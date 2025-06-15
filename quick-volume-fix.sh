#!/bin/bash

# Quick Volume Fix - Run this first
echo "🔧 Quick Docker Volume Fix"

# Stop services
docker compose down -v --remove-orphans

# Remove problematic volumes
docker volume rm nnp-smart-roster-compose_backup_volume 2>/dev/null || true
docker volume rm nnp-smart-roster-compose_redis_master_data 2>/dev/null || true
docker volume rm nnp-smart-roster-compose_redis_replica_data 2>/dev/null || true

# Create fresh volumes
docker volume create nnp-smart-roster-compose_backup_volume
docker volume create nnp-smart-roster-compose_redis_master_data
docker volume create nnp-smart-roster-compose_redis_replica_data

# Start services
docker compose up -d

echo "✅ Quick fix applied!"
