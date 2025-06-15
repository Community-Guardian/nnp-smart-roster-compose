#!/bin/bash

# =============================================================================
# DEPLOYMENT RECOVERY SCRIPT
# Fixes volume mount issues and restarts the deployment
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

log "🔧 Starting deployment recovery..."

# Step 1: Clean up failed containers and volumes
log "🧹 Cleaning up failed containers..."
docker compose down --remove-orphans 2>/dev/null || true

# Step 2: Remove any problematic volumes
log "🗑️ Removing problematic volumes..."
docker volume rm nnp-smart-roster-compose_prometheus_data 2>/dev/null || true
docker volume rm nnp-smart-roster-compose_elasticsearch_data 2>/dev/null || true
docker volume rm nnp-smart-roster-compose_backup_volume 2>/dev/null || true

# Step 3: Clean up networks
log "🌐 Cleaning up networks..."
docker network prune -f 2>/dev/null || true

# Step 4: Verify .env file exists and is populated
log "📋 Checking environment configuration..."
if [ ! -f .env ]; then
    error ".env file not found!"
    log "Creating .env from template..."
    if [ -f .env.example ]; then
        cp .env.example .env
        warn "Please edit .env with your actual values before continuing"
        exit 1
    else
        error "No .env.example found either!"
        exit 1
    fi
fi

# Check critical variables
MISSING_VARS=()
CRITICAL_VARS=("POSTGRES_PASSWORD" "DJANGO_SECRET_KEY" "REDIS_URL")

for var in "${CRITICAL_VARS[@]}"; do
    if ! grep -q "^${var}=" .env || grep -q "^${var}=$" .env; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    error "Missing or empty critical environment variables:"
    printf '%s\n' "${MISSING_VARS[@]}"
    error "Please set these variables in .env before continuing"
    exit 1
fi

log "✅ Environment configuration looks good"

# Step 5: Create required directories (if using bind mounts)
log "📁 Creating required directories..."
sudo mkdir -p /data/{prometheus,grafana,elasticsearch,backups} 2>/dev/null || {
    info "Could not create /data directories (may not be needed with Docker volumes)"
}

# Step 6: Start essential services first
log "🚀 Starting essential services..."

info "Starting database services..."
docker compose up -d postgres-primary postgres-replica 2>/dev/null || \
docker compose up -d postgres-master 2>/dev/null || \
docker compose up -d postgres 2>/dev/null || {
    warn "No PostgreSQL service found with expected names"
}

info "Starting cache services..."
docker compose up -d redis-master redis-replica 2>/dev/null || \
docker compose up -d redis 2>/dev/null || {
    warn "No Redis service found with expected names"
}

# Wait for databases to be ready
log "⏳ Waiting for databases to be ready..."
sleep 10

# Step 7: Start application services
info "Starting application services..."
docker compose up -d backend frontend 2>/dev/null || {
    warn "Backend or frontend services may not be defined"
}

# Step 8: Start supporting services (optional)
info "Starting supporting services..."
docker compose up -d nginx 2>/dev/null || {
    warn "Nginx service not found"
}

# Step 9: Start monitoring services (optional)
log "🔍 Starting monitoring services (if configured)..."
docker compose up -d prometheus grafana 2>/dev/null || {
    info "Monitoring services not started (may be optional)"
}

# Step 10: Show status
log "📊 Checking deployment status..."
sleep 5
docker compose ps

# Step 11: Health checks
log "🏥 Running health checks..."

# Check if services are responding
SERVICES_TO_CHECK=("backend:8000" "frontend:3000" "nginx:80")

for service in "${SERVICES_TO_CHECK[@]}"; do
    SERVICE_NAME=${service%:*}
    PORT=${service#*:}
    
    if curl -f -s "http://localhost:$PORT/health" >/dev/null 2>&1 || \
       curl -f -s "http://localhost:$PORT/" >/dev/null 2>&1; then
        log "✅ $SERVICE_NAME is responding on port $PORT"
    else
        warn "⚠️ $SERVICE_NAME may not be ready on port $PORT"
    fi
done

# Step 12: Show logs for debugging
log "📋 Recent logs (last 20 lines per service):"
echo ""
docker compose logs --tail=20 2>/dev/null || {
    warn "Could not retrieve logs"
}

log "🎉 Deployment recovery completed!"
echo ""
log "Next steps:"
log "1. Check 'docker compose ps' to see running services"
log "2. Review logs with 'docker compose logs -f [service-name]'"
log "3. Test application endpoints"
log "4. Monitor resource usage with 'docker stats'"

# Optional: show quick commands
echo ""
info "Useful commands:"
echo "  docker compose ps                    # Check service status"
echo "  docker compose logs -f backend      # Follow backend logs"
echo "  docker compose logs -f frontend     # Follow frontend logs"
echo "  docker compose down                 # Stop all services"
echo "  docker compose up -d                # Start in background"
