#!/bin/bash

# Comprehensive Docker Volume Fix Script
# This script fixes all volume mounting issues by cleaning up stale volumes and recreating them

echo "🔧 Comprehensive Docker Volume Fix for nnp-smart-roster-compose"
echo "=================================================="

# Stop all services
echo "📋 Step 1: Stopping all services..."
docker compose down -v --remove-orphans

# Remove ALL project-related volumes
echo "🗑️ Step 2: Removing all project volumes..."
docker volume ls -q | grep -E "(nnp-smart-roster|smartattend)" | xargs -r docker volume rm

# Remove any dangling volumes
echo "🧹 Step 3: Cleaning up dangling volumes..."
docker volume prune -f

# Clean up networks
echo "🌐 Step 4: Cleaning up networks..."
docker network prune -f

# Clean up any stopped containers
echo "🧹 Step 5: Cleaning up stopped containers..."
docker container prune -f

# Clean up unused images
echo "🖼️ Step 6: Cleaning up unused images..."
docker image prune -f

# Create the necessary host directories (if you want to use bind mounts)
echo "📁 Step 7: Creating host directories (optional)..."
sudo mkdir -p /data/backups
sudo mkdir -p /data/redis/master
sudo mkdir -p /data/redis/replica
sudo mkdir -p /data/postgres/primary
sudo mkdir -p /data/postgres/replica
sudo mkdir -p /data/logs
sudo chown -R $(whoami):$(whoami) /data/

# Recreate Docker managed volumes
echo "📦 Step 8: Creating fresh Docker volumes..."
docker volume create nnp-smart-roster-compose_redis_master_data
docker volume create nnp-smart-roster-compose_redis_replica_data
docker volume create nnp-smart-roster-compose_redis_logs
docker volume create nnp-smart-roster-compose_backup_volume
docker volume create nnp-smart-roster-compose_postgres_primary_data
docker volume create nnp-smart-roster-compose_postgres_replica_data
docker volume create nnp-smart-roster-compose_postgres_logs
docker volume create nnp-smart-roster-compose_prometheus_data
docker volume create nnp-smart-roster-compose_grafana_data
docker volume create nnp-smart-roster-compose_loki_data
docker volume create nnp-smart-roster-compose_elasticsearch_data
docker volume create nnp-smart-roster-compose_static_volume
docker volume create nnp-smart-roster-compose_media_volume
docker volume create nnp-smart-roster-compose_app_logs
docker volume create nnp-smart-roster-compose_nginx_logs
docker volume create nnp-smart-roster-compose_nginx_cache
docker volume create nnp-smart-roster-compose_pgadmin_data
docker volume create nnp-smart-roster-compose_alertmanager_data

# Verify volumes are created
echo "✅ Step 9: Verifying volumes..."
docker volume ls | grep nnp-smart-roster-compose

# Pull latest images
echo "📦 Step 10: Pulling latest images..."
docker compose pull

# Start services
echo "🚀 Step 11: Starting services..."
docker compose up -d

# Check status
echo "📊 Step 12: Checking service status..."
docker compose ps

echo ""
echo "✅ Volume fix complete!"
echo "📋 If you still see issues, check logs with:"
echo "   docker compose logs [service-name]"
echo ""
echo "🔍 To monitor services:"
echo "   docker compose ps"
echo "   docker compose logs -f"
