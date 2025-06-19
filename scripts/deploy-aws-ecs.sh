#!/bin/bash
# =============================================================================
# AWS ECS DEPLOYMENT SCRIPT
# Deploy SmartAttend to AWS ECS with auto-scaling
# =============================================================================

set -euo pipefail

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${ECS_CLUSTER_NAME:-smartattend-production}
SERVICE_NAME=${ECS_SERVICE_NAME:-smartattend-app}
TASK_FAMILY=${ECS_TASK_FAMILY:-smartattend-task}
ECR_REPOSITORY=${ECR_REPOSITORY:-smartattend}
DOMAIN=${DOMAIN:-your-domain.com}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed"
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials not configured"
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
    fi
    
    # Check environment variables
    if [ -z "${DOMAIN}" ]; then
        error "DOMAIN environment variable is not set"
    fi
    
    log "Prerequisites check passed"
}

# =============================================================================
# ECR REPOSITORY SETUP
# =============================================================================

setup_ecr() {
    log "Setting up ECR repository..."
    
    # Create ECR repository if it doesn't exist
    aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --region ${AWS_REGION} &> /dev/null || {
        log "Creating ECR repository: ${ECR_REPOSITORY}"
        aws ecr create-repository \
            --repository-name ${ECR_REPOSITORY} \
            --region ${AWS_REGION} \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256
    }
    
    # Get ECR login token
    aws ecr get-login-password --region ${AWS_REGION} | \
        docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
    
    log "ECR setup completed"
}

# =============================================================================
# BUILD AND PUSH IMAGES
# =============================================================================

build_and_push_images() {
    log "Building and pushing Docker images..."
    
    # Set AWS account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_URI=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}
    
    # Build images
    docker-compose -f docker-compose.yml build
    
    # Tag images for ECR
    docker tag nrad8393/signox-logx-system-backend-server:latest ${ECR_URI}:backend-latest
    docker tag nrad8393/signox-logx-system-frontend-server:latest ${ECR_URI}:frontend-latest
    docker tag nginx:alpine ${ECR_URI}:nginx-latest
    docker tag postgres:15-alpine ${ECR_URI}:postgres-latest
    docker tag redis:7-alpine ${ECR_URI}:redis-latest
    
    # Push images to ECR
    docker push ${ECR_URI}:backend-latest
    docker push ${ECR_URI}:frontend-latest
    docker push ${ECR_URI}:nginx-latest
    docker push ${ECR_URI}:postgres-latest
    docker push ${ECR_URI}:redis-latest
    
    log "Images pushed to ECR successfully"
}

# =============================================================================
# VPC AND NETWORKING SETUP
# =============================================================================

setup_networking() {
    log "Setting up VPC and networking..."
    
    # Create VPC
    VPC_ID=$(aws ec2 create-vpc \
        --cidr-block 10.0.0.0/16 \
        --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=smartattend-vpc}]" \
        --query 'Vpc.VpcId' \
        --output text)
    
    # Create Internet Gateway
    IGW_ID=$(aws ec2 create-internet-gateway \
        --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=smartattend-igw}]" \
        --query 'InternetGateway.InternetGatewayId' \
        --output text)
    
    # Attach Internet Gateway to VPC
    aws ec2 attach-internet-gateway \
        --internet-gateway-id ${IGW_ID} \
        --vpc-id ${VPC_ID}
    
    # Create public subnets
    SUBNET_1=$(aws ec2 create-subnet \
        --vpc-id ${VPC_ID} \
        --cidr-block 10.0.1.0/24 \
        --availability-zone ${AWS_REGION}a \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=smartattend-public-1}]" \
        --query 'Subnet.SubnetId' \
        --output text)
    
    SUBNET_2=$(aws ec2 create-subnet \
        --vpc-id ${VPC_ID} \
        --cidr-block 10.0.2.0/24 \
        --availability-zone ${AWS_REGION}b \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=smartattend-public-2}]" \
        --query 'Subnet.SubnetId' \
        --output text)
    
    # Create private subnets for database
    SUBNET_3=$(aws ec2 create-subnet \
        --vpc-id ${VPC_ID} \
        --cidr-block 10.0.3.0/24 \
        --availability-zone ${AWS_REGION}a \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=smartattend-private-1}]" \
        --query 'Subnet.SubnetId' \
        --output text)
    
    SUBNET_4=$(aws ec2 create-subnet \
        --vpc-id ${VPC_ID} \
        --cidr-block 10.0.4.0/24 \
        --availability-zone ${AWS_REGION}b \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=smartattend-private-2}]" \
        --query 'Subnet.SubnetId' \
        --output text)
    
    # Create route table
    ROUTE_TABLE=$(aws ec2 create-route-table \
        --vpc-id ${VPC_ID} \
        --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=smartattend-public-rt}]" \
        --query 'RouteTable.RouteTableId' \
        --output text)
    
    # Add route to internet gateway
    aws ec2 create-route \
        --route-table-id ${ROUTE_TABLE} \
        --destination-cidr-block 0.0.0.0/0 \
        --gateway-id ${IGW_ID}
    
    # Associate subnets with route table
    aws ec2 associate-route-table --subnet-id ${SUBNET_1} --route-table-id ${ROUTE_TABLE}
    aws ec2 associate-route-table --subnet-id ${SUBNET_2} --route-table-id ${ROUTE_TABLE}
    
    # Create security groups
    ALB_SG=$(aws ec2 create-security-group \
        --group-name smartattend-alb-sg \
        --description "Security group for SmartAttend ALB" \
        --vpc-id ${VPC_ID} \
        --query 'GroupId' \
        --output text)
    
    ECS_SG=$(aws ec2 create-security-group \
        --group-name smartattend-ecs-sg \
        --description "Security group for SmartAttend ECS tasks" \
        --vpc-id ${VPC_ID} \
        --query 'GroupId' \
        --output text)
    
    RDS_SG=$(aws ec2 create-security-group \
        --group-name smartattend-rds-sg \
        --description "Security group for SmartAttend RDS" \
        --vpc-id ${VPC_ID} \
        --query 'GroupId' \
        --output text)
    
    # Configure security group rules
    aws ec2 authorize-security-group-ingress \
        --group-id ${ALB_SG} \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0
    
    aws ec2 authorize-security-group-ingress \
        --group-id ${ALB_SG} \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0
        
    aws ec2 authorize-security-group-ingress \
        --group-id ${ECS_SG} \
        --protocol tcp \
        --port 80 \
        --source-group ${ALB_SG}
        
    aws ec2 authorize-security-group-ingress \
        --group-id ${RDS_SG} \
        --protocol tcp \
        --port 5432 \
        --source-group ${ECS_SG}
    
    # Export variables for later use
    export VPC_ID SUBNET_1 SUBNET_2 SUBNET_3 SUBNET_4 ALB_SG ECS_SG RDS_SG
    
    log "Networking setup completed"
}

# =============================================================================
# RDS SETUP
# =============================================================================

setup_rds() {
    log "Setting up RDS PostgreSQL..."
    
    # Create DB subnet group
    aws rds create-db-subnet-group \
        --db-subnet-group-name smartattend-db-subnet-group \
        --db-subnet-group-description "Subnet group for SmartAttend database" \
        --subnet-ids ${SUBNET_3} ${SUBNET_4}
    
    # Create RDS instance
    aws rds create-db-instance \
        --db-instance-identifier smartattend-prod-db \
        --db-instance-class db.t3.medium \
        --engine postgres \
        --engine-version 15.4 \
        --master-username ${POSTGRES_USER} \
        --master-user-password ${POSTGRES_PASSWORD} \
        --allocated-storage 100 \
        --storage-type gp2 \
        --storage-encrypted \
        --vpc-security-group-ids ${RDS_SG} \
        --db-subnet-group-name smartattend-db-subnet-group \
        --backup-retention-period 7 \
        --multi-az \
        --monitoring-interval 60 \
        --monitoring-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/rds-monitoring-role \
        --enable-performance-insights \
        --performance-insights-retention-period 7 \
        --deletion-protection
    
    log "RDS setup initiated (this will take several minutes)"
}

# =============================================================================
# ECS CLUSTER SETUP
# =============================================================================

setup_ecs_cluster() {
    log "Setting up ECS cluster..."
    
    # Create ECS cluster
    aws ecs create-cluster \
        --cluster-name ${CLUSTER_NAME} \
        --capacity-providers FARGATE \
        --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
        --configuration executeCommandConfiguration="{logging=OVERRIDE,logConfiguration={cloudWatchLogGroupName=/ecs/smartattend,cloudWatchEncryptionEnabled=true}}" \
        --tags key=Environment,value=Production key=Application,value=SmartAttend
    
    log "ECS cluster created: ${CLUSTER_NAME}"
}

# =============================================================================
# APPLICATION LOAD BALANCER SETUP
# =============================================================================

setup_alb() {
    log "Setting up Application Load Balancer..."
    
    # Create ALB
    ALB_ARN=$(aws elbv2 create-load-balancer \
        --name smartattend-alb \
        --subnets ${SUBNET_1} ${SUBNET_2} \
        --security-groups ${ALB_SG} \
        --scheme internet-facing \
        --type application \
        --ip-address-type ipv4 \
        --query 'LoadBalancers[0].LoadBalancerArn' \
        --output text)
    
    # Create target group
    TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
        --name smartattend-targets \
        --protocol HTTPS \
        --port 443 \
        --vpc-id ${VPC_ID} \
        --target-type ip \
        --health-check-enabled \
        --health-check-interval-seconds 30 \
        --health-check-path /health \
        --health-check-protocol HTTPS \
        --health-check-timeout-seconds 5 \
        --healthy-threshold-count 2 \
        --unhealthy-threshold-count 2 \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text)
    
    # Create HTTPS listener (assuming SSL certificate is already in ACM)
    aws elbv2 create-listener \
        --load-balancer-arn ${ALB_ARN} \
        --protocol HTTPS \
        --port 443 \
        --certificates CertificateArn=${ALB_CERTIFICATE_ARN} \
        --default-actions Type=forward,TargetGroupArn=${TARGET_GROUP_ARN}
    
    # Create HTTP listener (redirect to HTTPS)
    aws elbv2 create-listener \
        --load-balancer-arn ${ALB_ARN} \
        --protocol HTTP \
        --port 80 \
        --default-actions Type=redirect,RedirectConfig="{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}"
    
    # Get ALB DNS name
    ALB_DNS_NAME=$(aws elbv2 describe-load-balancers \
        --load-balancer-arns ${ALB_ARN} \
        --query 'LoadBalancers[0].DNSName' \
        --output text)
    
    export ALB_ARN TARGET_GROUP_ARN ALB_DNS_NAME
    
    log "ALB setup completed. DNS: ${ALB_DNS_NAME}"
}

# =============================================================================
# ECS TASK DEFINITION
# =============================================================================

create_task_definition() {
    log "Creating ECS task definition..."
    
    # Create task definition JSON
    cat > task-definition.json << EOF
{
  "family": "${TASK_FAMILY}",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "2048",
  "memory": "4096",
  "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "nginx-lb",
      "image": "${ECR_URI}:nginx-latest",
      "portMappings": [
        {
          "containerPort": 443,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/smartattend",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "nginx"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f https://localhost/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    },
    {
      "name": "smartattend-backend",
      "image": "${ECR_URI}:backend-latest",
      "essential": true,
      "environment": [
        {"name": "DATABASE_URL", "value": "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${RDS_ENDPOINT}:5432/${POSTGRES_DB}"},
        {"name": "REDIS_URL", "value": "redis://smartattend-redis:6379/0"},
        {"name": "DJANGO_SETTINGS_MODULE", "value": "config.settings.production"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/smartattend",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "backend"
        }
      },
      "healthCheck": {
        "command": ["CMD", "curl", "-f", "http://localhost:8000/health/"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    },
    {
      "name": "smartattend-frontend",
      "image": "${ECR_URI}:frontend-latest",
      "essential": true,
      "environment": [
        {"name": "NEXT_PUBLIC_API_URL", "value": "https://${DOMAIN}/api"},
        {"name": "NODE_ENV", "value": "production"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/smartattend",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "frontend"
        }
      },
      "healthCheck": {
        "command": ["CMD", "curl", "-f", "http://localhost:3000/api/health"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
EOF
    
    # Register task definition
    TASK_DEFINITION_ARN=$(aws ecs register-task-definition \
        --cli-input-json file://task-definition.json \
        --query 'taskDefinition.taskDefinitionArn' \
        --output text)
    
    export TASK_DEFINITION_ARN
    
    log "Task definition registered: ${TASK_DEFINITION_ARN}"
}

# =============================================================================
# ECS SERVICE DEPLOYMENT
# =============================================================================

deploy_service() {
    log "Deploying ECS service..."
    
    # Create ECS service
    aws ecs create-service \
        --cluster ${CLUSTER_NAME} \
        --service-name ${SERVICE_NAME} \
        --task-definition ${TASK_DEFINITION_ARN} \
        --desired-count 2 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_1},${SUBNET_2}],securityGroups=[${ECS_SG}],assignPublicIp=ENABLED}" \
        --load-balancers "targetGroupArn=${TARGET_GROUP_ARN},containerName=nginx-lb,containerPort=443" \
        --deployment-configuration "maximumPercent=200,minimumHealthyPercent=50,deploymentCircuitBreaker={enable=true,rollback=true}" \
        --enable-execute-command \
        --tags key=Environment,value=Production key=Application,value=SmartAttend
    
    log "ECS service deployment initiated"
}

# =============================================================================
# AUTO SCALING SETUP
# =============================================================================

setup_auto_scaling() {
    log "Setting up auto scaling..."
    
    # Register scalable target
    aws application-autoscaling register-scalable-target \
        --service-namespace ecs \
        --resource-id service/${CLUSTER_NAME}/${SERVICE_NAME} \
        --scalable-dimension ecs:service:DesiredCount \
        --min-capacity ${MIN_CAPACITY:-2} \
        --max-capacity ${MAX_CAPACITY:-20}
    
    # Create scaling policy for CPU
    aws application-autoscaling put-scaling-policy \
        --service-namespace ecs \
        --resource-id service/${CLUSTER_NAME}/${SERVICE_NAME} \
        --scalable-dimension ecs:service:DesiredCount \
        --policy-name smartattend-cpu-scaling \
        --policy-type TargetTrackingScaling \
        --target-tracking-scaling-policy-configuration file://cpu-scaling-policy.json
    
    # Create CPU scaling policy JSON
    cat > cpu-scaling-policy.json << EOF
{
  "TargetValue": ${TARGET_CPU_UTILIZATION:-70.0},
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "ScaleOutCooldown": 300,
  "ScaleInCooldown": 300
}
EOF
    
    log "Auto scaling configured"
}

# =============================================================================
# CLOUDWATCH MONITORING SETUP
# =============================================================================

setup_monitoring() {
    log "Setting up CloudWatch monitoring..."
    
    # Create CloudWatch Log Group
    aws logs create-log-group \
        --log-group-name /ecs/smartattend \
        --retention-in-days 30
    
    # Create CloudWatch Dashboard
    cat > dashboard.json << EOF
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "${SERVICE_NAME}", "ClusterName", "${CLUSTER_NAME}"],
          [".", "MemoryUtilization", ".", ".", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${AWS_REGION}",
        "title": "ECS Service Metrics"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${ALB_ARN}"],
          [".", "TargetResponseTime", ".", "."],
          [".", "HTTPCode_Target_5XX_Count", ".", "."]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "${AWS_REGION}",
        "title": "Load Balancer Metrics"
      }
    }
  ]
}
EOF
    
    aws cloudwatch put-dashboard \
        --dashboard-name SmartAttend-Production \
        --dashboard-body file://dashboard.json
    
    log "CloudWatch monitoring setup completed"
}

# =============================================================================
# DNS SETUP
# =============================================================================

setup_dns() {
    log "Setting up DNS records..."
    
    # Get hosted zone ID (assuming Route 53 is used)
    HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
        --dns-name ${DOMAIN} \
        --query 'HostedZones[0].Id' \
        --output text | cut -d'/' -f3)
    
    # Create DNS record pointing to ALB
    cat > dns-record.json << EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${DOMAIN}",
        "Type": "A",
        "AliasTarget": {
          "DNSName": "${ALB_DNS_NAME}",
          "EvaluateTargetHealth": true,
          "HostedZoneId": "Z35SXDOTRQ7X7K"
        }
      }
    }
  ]
}
EOF
    
    aws route53 change-resource-record-sets \
        --hosted-zone-id ${HOSTED_ZONE_ID} \
        --change-batch file://dns-record.json
    
    log "DNS records configured"
}

# =============================================================================
# MAIN DEPLOYMENT FUNCTION
# =============================================================================

main() {
    log "Starting AWS ECS deployment for SmartAttend..."
    
    # Check if required environment variables are set
    if [ -z "${AWS_ACCOUNT_ID:-}" ]; then
        export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    fi
    
    check_prerequisites
    setup_ecr
    build_and_push_images
    setup_networking
    setup_rds
    setup_ecs_cluster
    setup_alb
    create_task_definition
    deploy_service
    setup_auto_scaling
    setup_monitoring
    setup_dns
    
    log "Deployment completed successfully!"
    log "Application will be available at: https://${DOMAIN}"
    log "ALB DNS Name: ${ALB_DNS_NAME}"
    log "Monitor deployment status: aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME}"
    
    warn "Please note:"
    warn "1. RDS instance creation may take 10-15 minutes"
    warn "2. Wait for all services to be healthy before accessing the application"
    warn "3. Update your DNS records to point to the ALB if not using Route 53"
    warn "4. Configure SSL certificate in ACM and update ALB_CERTIFICATE_ARN"
}

# Run deployment
main "$@"
