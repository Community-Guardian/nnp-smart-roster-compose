# Redis Volume Fix Commands for Ubuntu Server
# Run these commands in order to fix the Redis volume mounting issue

# 1. Stop all services and remove volumes
echo "Stopping services and cleaning volumes..."
docker compose down -v --remove-orphans

# 2. Remove any existing volumes that might be conflicting
echo "Removing potentially conflicting volumes..."
docker volume ls -q | grep -E "(redis|nnp-smart-roster)" | xargs -r docker volume rm

# 3. Clean up dangling volumes
echo "Cleaning up dangling volumes..."
docker volume prune -f

# 4. Remove any Docker networks that might be stale
echo "Cleaning up networks..."
docker network prune -f

# 5. Pull latest images to ensure no caching issues
echo "Pulling latest images..."
docker compose pull

# 6. Start the services
echo "Starting services..."
docker compose up -d

# 7. Check the status
echo "Checking service status..."
docker compose ps

echo "✅ Fix complete! If you still see issues, run: docker compose logs redis-master"
