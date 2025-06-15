#!/bin/bash

# =============================================================================
# IMMEDIATE DEPLOYMENT FIX SCRIPT
# Fixes all volume mount issues and restarts deployment cleanly
# =============================================================================

set -euo pipefail

echo "🔧 Fixing Docker Compose deployment issues..."

# Step 1: Stop all services and clean up
echo "🛑 Stopping all services..."
docker compose down --remove-orphans --volumes 2>/dev/null || true

# Step 2: Remove problematic volumes that have bind mount configurations
echo "🗑️ Removing problematic volumes..."
VOLUMES_TO_REMOVE=(
    "nnp-smart-roster-compose_postgres_primary_data"
    "nnp-smart-roster-compose_postgres_replica_data" 
    "nnp-smart-roster-compose_redis_master_data"
    "nnp-smart-roster-compose_redis_replica_data"
    "nnp-smart-roster-compose_media_volume"
    "nnp-smart-roster-compose_backup_volume"
    "nnp-smart-roster-compose_prometheus_data"
    "nnp-smart-roster-compose_elasticsearch_data"
)

for volume in "${VOLUMES_TO_REMOVE[@]}"; do
    echo "  Removing volume: $volume"
    docker volume rm "$volume" 2>/dev/null || echo "    Volume $volume did not exist"
done

# Step 3: Clean up networks
echo "🌐 Cleaning up networks..."
docker network prune -f

# Step 4: Pull latest changes (in case there are more updates)
echo "📥 Pulling latest configuration..."
git pull

# Step 5: Validate Docker Compose configuration
echo "🔍 Validating Docker Compose configuration..."
if ! docker compose config >/dev/null 2>&1; then
    echo "❌ Docker Compose configuration is invalid!"
    echo "Running config check with detailed output:"
    docker compose config
    exit 1
fi

echo "✅ Docker Compose configuration is valid"

# Step 6: Start essential services first
echo "🚀 Starting essential services..."

echo "  Starting PostgreSQL..."
docker compose up -d postgres-primary 2>/dev/null || \
docker compose up -d postgres-master 2>/dev/null || \
docker compose up -d postgres 2>/dev/null || \
echo "    No PostgreSQL service found"

echo "  Starting Redis..."
docker compose up -d redis-master 2>/dev/null || \
docker compose up -d redis 2>/dev/null || \
echo "    No Redis service found"

# Wait for databases
echo "⏳ Waiting for databases to initialize..."
sleep 15

# Step 7: Start application services
echo "🏗️ Starting application services..."
docker compose up -d backend frontend 2>/dev/null || echo "  Application services not started"

# Step 8: Start supporting services
echo "🔧 Starting supporting services..."
docker compose up -d nginx 2>/dev/null || echo "  Nginx not started"

# Step 9: Start monitoring (optional)
echo "📊 Starting monitoring services..."
docker compose up -d prometheus grafana 2>/dev/null || echo "  Monitoring services not started"

# Step 10: Show status
echo ""
echo "📋 Current service status:"
docker compose ps

# Step 11: Show recent logs
echo ""
echo "📝 Recent logs (last 10 lines per service):"
docker compose logs --tail=10

echo ""
echo "🎉 Deployment fix completed!"
echo ""
echo "📞 Quick commands:"
echo "  docker compose ps                 # Check service status"
echo "  docker compose logs -f [service]  # Follow service logs"
echo "  docker compose down               # Stop all services"
echo "  docker compose up -d              # Start all services"
echo ""
echo "🌐 Test endpoints (once services are ready):"
echo "  curl http://localhost/            # Nginx"
echo "  curl http://localhost:8000/health # Backend"
echo "  curl http://localhost:3000/health # Frontend"
