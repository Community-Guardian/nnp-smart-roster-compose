# Docker Compose Deployment Troubleshooting Guide

## Environment Variables Check

Ensure these critical variables are set in your `.env` file:

```bash
# Check if .env exists and has content
ls -la .env
cat .env | head -20

# Required variables (check these are not empty)
grep -E "POSTGRES_PASSWORD|DJANGO_SECRET_KEY|NEXTAUTH_SECRET" .env
```

## Network Troubleshooting

```bash
# Check existing networks
docker network ls

# Remove conflicting networks
docker network rm smartattend-app smartattend-cache smartattend-db smartattend-monitor 2>/dev/null || true

# Prune unused networks
docker network prune -f

# Check Docker daemon logs if issues persist
sudo journalctl -u docker.service --since "1 hour ago"
```

## Service Health Check

```bash
# Check service status
docker compose ps

# Check logs for specific services
docker compose logs postgres-master
docker compose logs redis-master
docker compose logs backend
docker compose logs frontend

# Check if ports are accessible
curl -f http://localhost:8000/health/ || echo "Backend not ready"
curl -f http://localhost:3000/api/health || echo "Frontend not ready"
```

## Common Issues and Solutions

### Issue 1: Port Conflicts
```bash
# Check what's using the ports
sudo netstat -tlnp | grep -E ':80|:443|:5432|:6379|:8000|:3000'

# Kill processes using the ports (if safe to do so)
sudo lsof -ti:80 | xargs sudo kill -9
```

### Issue 2: Disk Space
```bash
# Check disk space
df -h

# Clean up Docker if needed
docker system prune -a --volumes
```

### Issue 3: Memory Issues
```bash
# Check memory usage
free -h

# Increase swap if needed
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## Step-by-Step Debugging

1. **Check Docker Installation**
   ```bash
   docker --version
   docker compose version
   ```

2. **Validate Compose File**
   ```bash
   docker compose config
   ```

3. **Start Services Individually**
   ```bash
   # Start database first
   docker compose up postgres-master
   
   # In another terminal, check if it's ready
   docker compose exec postgres-master pg_isready -U smartattend_user
   ```

4. **Check Service Dependencies**
   ```bash
   # Make sure backend can connect to database
   docker compose run --rm backend python smartAttend/manage.py check --database default
   ```

## Success Indicators

Your deployment is successful when:

- `docker compose ps` shows all services as "running"
- `curl http://localhost/health` returns HTTP 200
- `curl http://localhost:3000/api/health` returns HTTP 200
- No error messages in `docker compose logs`

## Quick Recovery Commands

```bash
# If everything fails, nuclear option:
docker compose down --volumes --remove-orphans
docker system prune -a --volumes
docker compose up -d

# Or start fresh with minimal setup:
docker compose -f compose.minimal.yaml up -d
```

## Getting Help

If issues persist, please share:
1. Output of `docker compose ps`
2. Output of `docker compose logs --tail=50`
3. Your `.env` file (with sensitive values redacted)
4. System information: `uname -a` and `docker info`

## Updated Environment Configuration ✅

Your environment has been updated with the correct values:

### Critical Configuration
- **Database**: PostgreSQL with `postgres:user@12345@postgres:5432/smartattend`
- **Cache**: Redis at `redis://redis:6379/0`
- **Domain**: `smartAttend.com` with ngrok tunnel
- **API URL**: `https://logx.thenyeripoly.ac.ke/smartAttend`
- **Frontend URL**: `https://logx.thenyeripoly.ac.ke/`

### Pre-Deployment Checklist

1. **Verify Environment Variables**
   ```bash
   # Linux/WSL
   ./scripts/verify-env.sh
   
   # Windows PowerShell
   .\scripts\verify-env.ps1
   ```

2. **Ensure ngrok Tunnel is Active**
   ```bash
   curl -I https://logx.thenyeripoly.ac.ke/
   # Should return HTTP 200 or 302
   ```

3. **Clean Previous Deployment**
   ```bash
   docker compose down --volumes --remove-orphans
   docker network prune -f
   ```

4. **Start Services in Order**
   ```bash
   # Start database and cache first
   docker compose up -d postgres redis
   
   # Wait for them to be ready
   sleep 30
   
   # Start application services
   docker compose up -d backend frontend
   
   # Start load balancer
   docker compose up -d nginx
   ```

### Service Verification Commands

```bash
# Check all services are running
docker compose ps

# Test database connection
docker compose exec postgres psql -U postgres -d smartattend -c "SELECT version();"

# Test Redis connection  
docker compose exec redis redis-cli ping

# Test backend health
curl -f http://localhost:8000/health/

# Test frontend health
curl -f http://localhost:3000/api/health

# Check logs
docker compose logs --tail=50 backend
docker compose logs --tail=50 frontend
```

## React 19 Dependency Conflict Fix ❌➡️✅

**Issue**: Docker build fails with `ERESOLVE could not resolve` error for React 19 compatibility.

**Error Message**: 
```
peer react@"^16.8 || ^17.0 || ^18.0" from vaul@0.9.9
Could not resolve dependency conflict with react@19.1.0
```

### Quick Fix (Apply immediately):

1. **Navigate to frontend directory**:
   ```bash
   cd ~/attendance/nnp-smart-roster-frontend/smart-attendance
   ```

2. **Clean and reinstall dependencies**:
   ```bash
   # Remove existing dependencies
   rm -rf node_modules package-lock.json
   
   # Install with legacy peer deps to resolve React 19 conflicts
   npm install --legacy-peer-deps
   
   # Create new package-lock.json
   npm audit fix --legacy-peer-deps
   ```

3. **Update vaul package** (in package.json):
   ```json
   "vaul": "^1.0.0"
   ```

4. **Test Docker build**:
   ```bash
   docker build -t smartattend-frontend:test .
   ```

### Alternative Fix Scripts:

**Linux/WSL**:
```bash
cd ~/attendance/nnp-smart-roster-frontend/smart-attendance
./scripts/fix-dependencies.sh
```

**Windows PowerShell**:
```powershell
cd c:\Users\karan\Documents\GitHub\nnp-smart-roster-frontend\smart-attendance
.\scripts\fix-dependencies.ps1
```

### Root Cause:
- React 19 is not yet supported by some packages like `vaul@0.9.x`
- The Dockerfile now includes `--legacy-peer-deps` flag to handle this
- Updated vaul to v1.0.0 which has better React 19 support
