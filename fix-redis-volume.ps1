# Fix Redis Volume Mount Issue
# This script resolves the Redis volume mounting error by cleaning up conflicting volumes

Write-Host "🔧 Fixing Redis volume mount issue..." -ForegroundColor Yellow

# Stop all services
Write-Host "📋 Stopping all services..." -ForegroundColor Blue
docker compose down -v --remove-orphans

# Remove volumes that contain redis or project name
Write-Host "🗑️ Removing conflicting volumes..." -ForegroundColor Blue
$volumes = docker volume ls -q | Where-Object { $_ -match "(redis|nnp-smart-roster-compose)" }
if ($volumes) {
    $volumes | ForEach-Object { docker volume rm $_ }
}

# Clean up any dangling volumes
Write-Host "🧹 Cleaning up dangling volumes..." -ForegroundColor Blue
docker volume prune -f

# Remove any cached images that might have volume conflicts
Write-Host "🔄 Removing cached images..." -ForegroundColor Blue
docker image prune -f

# Recreate the volumes with proper configuration
Write-Host "📦 Creating fresh volumes..." -ForegroundColor Blue
docker volume create nnp-smart-roster-compose_redis_master_data
docker volume create nnp-smart-roster-compose_redis_replica_data
docker volume create nnp-smart-roster-compose_redis_logs

# Verify volumes are created
Write-Host "✅ Verifying volumes..." -ForegroundColor Green
docker volume ls | Select-String redis

# Start services
Write-Host "🚀 Starting services..." -ForegroundColor Green
docker compose up -d

Write-Host "✅ Redis volume issue should now be resolved!" -ForegroundColor Green
Write-Host "📊 Check service status with: docker compose ps" -ForegroundColor Cyan
