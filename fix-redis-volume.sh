#!/bin/bash

# Fix Redis Volume Mount Issue
# This script resolves the Redis volume mounting error by cleaning up conflicting volumes

echo "🔧 Fixing Redis volume mount issue..."

# Stop all services
echo "📋 Stopping all services..."
docker compose down -v --remove-orphans

# Remove all volumes to clear any conflicting configurations
echo "🗑️ Removing all volumes..."
docker volume ls -q | grep -E "(redis|nnp-smart-roster-compose)" | xargs -r docker volume rm

# Clean up any dangling volumes
echo "🧹 Cleaning up dangling volumes..."
docker volume prune -f

# Remove any cached images that might have volume conflicts
echo "🔄 Removing cached images..."
docker image prune -f

# Recreate the volumes with proper configuration
echo "📦 Creating fresh volumes..."
docker volume create nnp-smart-roster-compose_redis_master_data
docker volume create nnp-smart-roster-compose_redis_replica_data
docker volume create nnp-smart-roster-compose_redis_logs

# Verify volumes are created
echo "✅ Verifying volumes..."
docker volume ls | grep redis

# Start services
echo "🚀 Starting services..."
docker compose up -d

echo "✅ Redis volume issue should now be resolved!"
echo "📊 Check service status with: docker compose ps"
