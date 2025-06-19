# SmartAttend Production Deployment Guide

## 🚀 Production-Grade Infrastructure for 20,000+ Daily Users

This deployment configuration provides a robust, scalable, and monitored infrastructure for the SmartAttend system, designed to handle high-traffic loads with zero downtime requirements.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Database External Access](#database-external-access)
- [AWS ECS Deployment](#aws-ecs-deployment)
- [SSL/HTTPS Configuration](#ssl-https-configuration)
- [Monitoring & Observability](#monitoring--observability)
- [Backup & Recovery](#backup--recovery)
- [Security Considerations](#security-considerations)
- [Performance Tuning](#performance-tuning)
- [Troubleshooting](#troubleshooting)

## 🏗 Architecture Overview

### High-Level Architecture
```
Internet → Load Balancer → Nginx → Application Services
                      ↓
Database Cluster ← Connection Pooler ← Cache Cluster
                      ↓
Monitoring Stack ← Log Aggregation ← Alerting System
```

### Core Components

#### **Application Tier**
- **Frontend**: Next.js application (3 replicas)
- **Backend**: Django application (4 replicas)
- **Workers**: Celery workers (3 replicas)
- **Scheduler**: Celery beat scheduler

#### **Data Tier**
- **Primary Database**: PostgreSQL 15 with optimized configuration
- **Read Replica**: PostgreSQL replica for read operations
- **Cache Layer**: Redis cluster (master + replica)
- **Connection Pooling**: PgBouncer for database connections

#### **Infrastructure Tier**
- **Load Balancer**: Nginx with SSL termination
- **Monitoring**: Prometheus + Grafana + Loki + Jaeger
- **Alerting**: AlertManager with multi-channel notifications
- **Backup**: Automated backup system with S3 integration

## 📋 Prerequisites

### System Requirements
- **CPU**: Minimum 8 cores (recommended 16+ cores)
- **RAM**: Minimum 16GB (recommended 32GB+)
- **Storage**: Minimum 500GB SSD (recommended 1TB+ NVMe)
- **Network**: High-bandwidth connection (1Gbps+)

### Software Requirements
- Docker Engine 24.0+
- Docker Compose 2.20+
- AWS CLI (for ECS deployment)
- OpenSSL (for certificate management)

### Domain Requirements
- Registered domain name
- DNS control for domain
- SSL certificate (Let's Encrypt or commercial)

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd nnp-smart-roster-compose

# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

### 2. Configure Environment Variables
Edit `.env` file with your specific values:

```bash
# Domain Configuration
DOMAIN=your-domain.com
POSTGRES_PASSWORD=your_secure_password
# ... (see .env.example for all variables)
```

### 3. Create Required Directories
```bash
# Create data directories
sudo mkdir -p /data/{postgres/{primary,replica},redis/{master,replica},media,backups,prometheus,elasticsearch}

# Set proper permissions
sudo chown -R 1000:1000 /data
```

### 4. SSL Certificate Setup

#### Option A: Let's Encrypt (Recommended)
```bash
# Install certbot
sudo apt-get install certbot

# Obtain certificate
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com

# Copy certificates
sudo mkdir -p ./ssl
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ./ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ./ssl/key.pem
```

#### Option B: Self-Signed (Development)
```bash
mkdir -p ./ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ./ssl/key.pem \
    -out ./ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=your-domain.com"
```

### 5. Deploy the Stack
```bash
# Start all services
docker-compose up -d

# Check service health
docker-compose ps

# View logs
docker-compose logs -f
```

## 🗄 Database External Access

The configuration includes secure external database access for administration:

### Access Methods

#### 1. Direct PostgreSQL Connection
```bash
# Primary database (Port 5432)
psql -h your-domain.com -p 5432 -U smartattend_user -d smartattend_prod
```

#### 2. PgAdmin Web Interface
```
URL: https://your-domain.com/pgadmin/
Email: admin@your-domain.com
Password: [PGADMIN_DEFAULT_PASSWORD]
```

#### 3. Connection Pooler (Recommended for applications)
```bash
# Through PgBouncer (Port 6432)
psql -h your-domain.com -p 6432 -U smartattend_user -d smartattend_prod
```

### Security Considerations for Database Access

1. **IP Whitelisting**: Uncomment and configure IP restrictions in `nginx/production.conf`
2. **VPN Access**: Consider requiring VPN for database administration
3. **Audit Logging**: All database connections are logged for security monitoring

## ☁️ AWS ECS Deployment

### Prerequisites
```bash
# Install AWS CLI
pip install awscli

# Configure AWS credentials
aws configure
```

### ECS Task Definition
```json
{
  "family": "smartattend-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "2048",
  "memory": "4096",
  "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::account:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "nginx-lb",
      "image": "nginx:alpine",
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
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "nginx"
        }
      }
    }
  ]
}
```

### Application Load Balancer Configuration
```bash
# Create ALB
aws elbv2 create-load-balancer \
    --name smartattend-alb \
    --subnets subnet-12345 subnet-67890 \
    --security-groups sg-12345 \
    --scheme internet-facing \
    --type application

# Create target group
aws elbv2 create-target-group \
    --name smartattend-targets \
    --protocol HTTPS \
    --port 443 \
    --vpc-id vpc-12345 \
    --target-type ip \
    --health-check-path /health
```

### Auto Scaling Configuration
```json
{
  "ServiceName": "smartattend-service",
  "ClusterName": "smartattend-production",
  "ScalableDimension": "ecs:service:DesiredCount",
  "MinCapacity": 2,
  "MaxCapacity": 20,
  "TargetValue": 70.0,
  "MetricType": "ECSServiceAverageCPUUtilization"
}
```

## 🔒 SSL/HTTPS Configuration

### Nginx SSL Configuration
The production configuration includes:

- **TLS 1.2/1.3 only**: Modern cipher suites
- **HSTS**: HTTP Strict Transport Security
- **OCSP Stapling**: Certificate validation
- **Perfect Forward Secrecy**: Ephemeral key exchange

### Certificate Management
```bash
# Automated renewal with cron
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

### SSL Testing
```bash
# Test SSL configuration
curl -I https://your-domain.com

# SSL Labs test
https://www.ssllabs.com/ssltest/analyze.html?d=your-domain.com
```

## 📊 Monitoring & Observability

### Access URLs
- **Grafana**: https://your-domain.com:3001 (admin/password)
- **Prometheus**: https://your-domain.com:9090
- **Jaeger**: https://your-domain.com:16686
- **AlertManager**: https://your-domain.com:9093

### Key Metrics Monitored

#### System Metrics
- CPU, Memory, Disk usage
- Network I/O and latency
- Load averages

#### Application Metrics
- Request rate and response time
- Error rates (4xx, 5xx)
- Database query performance
- Cache hit/miss ratios

#### Business Metrics
- User login rates
- Active users
- Feature usage statistics
- Performance KPIs

### Alerting Rules
Critical alerts are configured for:

- **System**: High CPU/memory/disk usage
- **Database**: Connection issues, replication lag
- **Application**: High error rates, slow responses
- **Security**: Authentication failures, suspicious activity

### Dashboard Access
Import pre-built dashboards from `monitoring/grafana/dashboards/`:

1. **System Overview**: Infrastructure metrics
2. **Application Performance**: App-specific metrics
3. **Database Performance**: PostgreSQL metrics
4. **Business Intelligence**: User and usage analytics

## 💾 Backup & Recovery

### Automated Backup System
The backup system runs daily and includes:

- **Database**: Full and incremental backups
- **Media Files**: User uploads and static content
- **Configuration**: All service configurations
- **Logs**: Application and system logs

### Backup Schedule
```bash
# Daily backups at 2 AM
0 2 * * * /usr/local/bin/backup.sh

# Weekly full backup
0 2 * * 0 /usr/local/bin/backup.sh --full

# Monthly archive to cold storage
0 2 1 * * /usr/local/bin/backup.sh --archive
```

### Recovery Procedures

#### Database Recovery
```bash
# Restore from backup
PGPASSWORD="password" pg_restore \
    -h postgres-primary \
    -U smartattend_user \
    -d smartattend_prod \
    -v backup_file.sql.gz
```

#### Media Files Recovery
```bash
# Extract media backup
tar -xzf media_files_backup.tar.gz -C /data/media/
```

### Disaster Recovery
1. **RTO (Recovery Time Objective)**: < 4 hours
2. **RPO (Recovery Point Objective)**: < 1 hour
3. **Multi-region backup**: AWS S3 cross-region replication

## 🔐 Security Considerations

### Network Security
- **Isolated Networks**: Separate networks for different tiers
- **Firewall Rules**: Restrictive ingress/egress rules
- **DDoS Protection**: Rate limiting and connection throttling

### Application Security
- **HTTPS Everywhere**: All communications encrypted
- **Security Headers**: HSTS, CSP, X-Frame-Options
- **Input Validation**: SQL injection protection
- **Authentication**: Multi-factor authentication support

### Data Security
- **Encryption at Rest**: Database and file encryption
- **Encryption in Transit**: TLS 1.3 for all communications
- **Access Controls**: Role-based access control (RBAC)
- **Audit Logging**: Complete audit trail

### Container Security
- **Image Scanning**: Vulnerability scanning
- **Runtime Security**: Container isolation
- **Secrets Management**: Encrypted secrets storage

## ⚡ Performance Tuning

### Database Optimization
```sql
-- Key PostgreSQL settings for high load
shared_buffers = 512MB
effective_cache_size = 1536MB
work_mem = 8MB
max_connections = 500
random_page_cost = 1.1
effective_io_concurrency = 200
```

### Cache Optimization
```bash
# Redis optimization for high concurrency
maxmemory 1gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
```

### Application Tuning
```bash
# Gunicorn workers calculation
# workers = (2 x CPU cores) + 1
GUNICORN_WORKERS=4
GUNICORN_THREADS=4
GUNICORN_MAX_REQUESTS=1000
```

### Load Balancer Tuning
```nginx
# Nginx optimization for high load
worker_processes auto;
worker_connections 4096;
keepalive_requests 1000;
client_max_body_size 100m;
```

## 🐛 Troubleshooting

### Common Issues

#### High Load Issues
```bash
# Check system resources
htop
iostat -x 1
docker stats

# Check database connections
docker exec -it pgbouncer psql -h localhost -p 6432 -U pgbouncer pgbouncer -c "SHOW POOLS;"
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
docker exec -it postgres-primary pg_isready

# Check connection pooler
docker logs pgbouncer

# Monitor active connections
docker exec -it postgres-primary psql -U smartattend_user -c "SELECT count(*) FROM pg_stat_activity;"
```

#### Application Errors
```bash
# Check application logs
docker logs signoxlogxsytembackend

# Check Celery workers
docker logs celery-worker

# Monitor error rates
curl -s http://localhost:9090/api/v1/query?query=rate(nginx_http_requests_total{status=~"5.."}[5m])
```

#### Memory Issues
```bash
# Check memory usage by service
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Check for memory leaks
docker exec -it signoxlogxsytembackend ps aux --sort=-%mem | head
```

### Performance Debugging
```bash
# Database query analysis
docker exec -it postgres-primary psql -U smartattend_user -c "SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Cache performance
docker exec -it redis-master redis-cli info stats

# Application profiling
docker exec -it signoxlogxsytembackend python manage.py shell -c "
from django.test.utils import override_settings
import cProfile
# Profile critical code paths
"
```

### Log Analysis
```bash
# Centralized log search
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
    --data-urlencode 'query={job="smartattend-backend"}' \
    --data-urlencode 'start=2024-01-01T00:00:00Z' \
    --data-urlencode 'end=2024-01-01T23:59:59Z'

# Error pattern analysis
grep -E "(ERROR|CRITICAL|FATAL)" /var/log/app/*.log | sort | uniq -c | sort -nr
```

## 📞 Support

### Monitoring Channels
- **Slack**: #smartattend-alerts
- **Email**: ops@your-domain.com
- **PagerDuty**: Critical incidents only

### Emergency Procedures
1. **Critical Issue**: Page on-call engineer
2. **Database Issue**: Contact DBA team
3. **Security Issue**: Contact security team immediately
4. **Application Issue**: Contact development team

### Health Check URLs
- **Application**: https://your-domain.com/health
- **API**: https://your-domain.com/api/health
- **Database**: Internal monitoring only

---

## 🏆 Production Readiness Checklist

- [ ] SSL certificates configured and tested
- [ ] Database external access working
- [ ] All monitoring dashboards accessible
- [ ] Backup system tested and verified
- [ ] Alert notifications configured
- [ ] Performance baselines established
- [ ] Security scans completed
- [ ] Load testing performed
- [ ] Disaster recovery plan tested
- [ ] Documentation updated

## 📚 Additional Resources

- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [Redis Best Practices](https://redis.io/docs/manual/config/)
- [Nginx Performance Tuning](https://nginx.org/en/docs/http/ngx_http_core_module.html)
- [Docker Production Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)

---

**Last Updated**: $(date)  
**Version**: 1.0.0  
**Maintained By**: DevOps Team
