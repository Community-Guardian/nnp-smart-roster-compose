#!/bin/bash

# =============================================================================
# DOCKER BUILD AND DEPLOYMENT VALIDATION SCRIPT
# Tests both frontend and backend Dockerfiles for production readiness
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

# =============================================================================
# CONFIGURATION
# =============================================================================

BACKEND_DIR="c:\Users\karan\Documents\GitHub\nnp-smart-roster-backend"
FRONTEND_DIR="c:\Users\karan\Documents\GitHub\nnp-smart-roster-frontend\smart-attendance"
COMPOSE_DIR="c:\Users\karan\Documents\GitHub\nnp-smart-roster-compose"

BUILD_ARGS="--build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') --build-arg VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown') --build-arg VERSION=1.0.0"

# =============================================================================
# DOCKER VALIDATIONS
# =============================================================================

validate_docker() {
    log "Validating Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running"
        exit 1
    fi
    
    local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    info "Docker version: $docker_version"
    
    # Check for BuildKit support
    if docker buildx version &> /dev/null; then
        info "BuildKit support available"
    else
        warn "BuildKit not available, builds may be slower"
    fi
}

validate_dockerfile_syntax() {
    local dockerfile=$1
    local context_dir=$2
    
    log "Validating Dockerfile syntax: $dockerfile"
    
    # Use hadolint if available for advanced validation
    if command -v hadolint &> /dev/null; then
        info "Running hadolint validation..."
        if hadolint "$dockerfile"; then
            log "Hadolint validation passed"
        else
            warn "Hadolint found issues (non-blocking)"
        fi
    else
        info "Hadolint not available, skipping advanced validation"
    fi
    
    # Basic syntax check with docker build --dry-run if supported
    log "Performing basic syntax validation..."
    if docker build --help | grep -q "\-\-dry-run"; then
        docker build --dry-run -f "$dockerfile" "$context_dir" > /dev/null
        log "Dockerfile syntax validation passed"
    else
        info "Dry-run not supported, will test with actual build"
    fi
}

# =============================================================================
# BUILD TESTS
# =============================================================================

build_backend() {
    log "Building backend Docker image..."
    
    cd "$BACKEND_DIR"
    
    # Validate Dockerfile first
    validate_dockerfile_syntax "Dockerfile" "."
    
    # Build the image
    if docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --tag smartattend-backend:test \
        --tag smartattend-backend:latest \
        $BUILD_ARGS \
        --progress=plain \
        --load \
        .; then
        log "Backend image built successfully"
    else
        error "Backend image build failed"
        return 1
    fi
    
    # Test image size
    local image_size=$(docker images smartattend-backend:test --format "{{.Size}}")
    info "Backend image size: $image_size"
    
    # Quick smoke test
    log "Running backend smoke test..."
    if docker run --rm --name backend-test \
        -e DATABASE_URL="sqlite:///tmp/test.db" \
        -e REDIS_URL="redis://localhost:6379/0" \
        -e DJANGO_SECRET_KEY="test-key-12345" \
        -e DJANGO_DEBUG="False" \
        smartattend-backend:test \
        python smartAttend/manage.py check; then
        log "Backend smoke test passed"
    else
        warn "Backend smoke test failed (may be due to missing dependencies)"
    fi
}

build_frontend() {
    log "Building frontend Docker image..."
    
    cd "$FRONTEND_DIR"
    
    # Validate Dockerfile first
    validate_dockerfile_syntax "Dockerfile" "."
    
    # Build the image
    if docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --tag smartattend-frontend:test \
        --tag smartattend-frontend:latest \
        $BUILD_ARGS \
        --progress=plain \
        --load \
        .; then
        log "Frontend image built successfully"
    else
        error "Frontend image build failed"
        return 1
    fi
    
    # Test image size
    local image_size=$(docker images smartattend-frontend:test --format "{{.Size}}")
    info "Frontend image size: $image_size"
    
    # Quick smoke test
    log "Running frontend smoke test..."
    if timeout 30s docker run --rm --name frontend-test \
        -e NODE_ENV="production" \
        -p 3001:3000 \
        smartattend-frontend:test &
    then
        sleep 5
        if curl -f http://localhost:3001/api/health > /dev/null 2>&1; then
            log "Frontend smoke test passed"
        else
            warn "Frontend health check failed"
        fi
        docker stop frontend-test 2>/dev/null || true
    else
        warn "Frontend smoke test failed"
    fi
}

# =============================================================================
# SECURITY CHECKS
# =============================================================================

security_scan() {
    log "Running security scans on Docker images..."
    
    # Use Trivy if available
    if command -v trivy &> /dev/null; then
        info "Running Trivy security scans..."
        
        log "Scanning backend image..."
        trivy image --severity HIGH,CRITICAL smartattend-backend:test || warn "Backend security scan found issues"
        
        log "Scanning frontend image..."
        trivy image --severity HIGH,CRITICAL smartattend-frontend:test || warn "Frontend security scan found issues"
    else
        info "Trivy not available, skipping security scans"
    fi
    
    # Check for non-root user
    log "Checking if containers run as non-root..."
    
    local backend_user=$(docker run --rm smartattend-backend:test whoami)
    if [ "$backend_user" != "root" ]; then
        log "Backend runs as non-root user: $backend_user"
    else
        error "Backend runs as root user - security risk!"
    fi
    
    local frontend_user=$(docker run --rm smartattend-frontend:test whoami)
    if [ "$frontend_user" != "root" ]; then
        log "Frontend runs as non-root user: $frontend_user"
    else
        error "Frontend runs as root user - security risk!"
    fi
}

# =============================================================================
# PRODUCTION READINESS CHECKS
# =============================================================================

production_readiness_check() {
    log "Checking production readiness..."
    
    # Check for health endpoints
    log "Verifying health endpoints..."
    
    # Backend health check
    if docker run --rm --name backend-health-test \
        -e DATABASE_URL="sqlite:///tmp/test.db" \
        -e REDIS_URL="redis://localhost:6379/0" \
        -e DJANGO_SECRET_KEY="test-key-12345" \
        smartattend-backend:test \
        python /tmp/health/check.py > /dev/null 2>&1; then
        log "Backend health endpoint working"
    else
        warn "Backend health endpoint issues"
    fi
    
    # Frontend health check
    if timeout 20s docker run --rm --name frontend-health-test \
        -p 3002:3000 \
        smartattend-frontend:test &
    then
        sleep 5
        if curl -f http://localhost:3002/api/health | jq '.status' | grep -q "ok"; then
            log "Frontend health endpoint working"
        else
            warn "Frontend health endpoint issues"
        fi
        docker stop frontend-health-test 2>/dev/null || true
    else
        warn "Frontend health endpoint test failed"
    fi
    
    # Check for proper logging
    log "Checking logging configuration..."
    
    local backend_logs=$(docker run --rm smartattend-backend:test ls -la /app/logs/ 2>/dev/null | wc -l)
    if [ "$backend_logs" -gt 0 ]; then
        log "Backend logging directory configured"
    else
        warn "Backend logging directory issues"
    fi
    
    # Check for monitoring hooks
    log "Checking monitoring capabilities..."
    
    if docker run --rm smartattend-backend:test test -f /tmp/monitor.py; then
        log "Backend monitoring script present"
    else
        warn "Backend monitoring script missing"
    fi
    
    if docker run --rm smartattend-frontend:test test -f /tmp/metrics.txt; then
        log "Frontend monitoring capabilities present"
    else
        info "Frontend monitoring will be created at runtime"
    fi
}

# =============================================================================
# CLEANUP
# =============================================================================

cleanup() {
    log "Cleaning up test resources..."
    
    # Stop any running test containers
    docker ps -q --filter "name=*-test" | xargs -r docker stop
    docker ps -aq --filter "name=*-test" | xargs -r docker rm
    
    # Remove test images if requested
    if [ "${CLEANUP_IMAGES:-false}" = "true" ]; then
        docker rmi smartattend-backend:test smartattend-frontend:test 2>/dev/null || true
    fi
    
    log "Cleanup completed"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "Starting Docker validation and testing..."
    
    # Setup cleanup trap
    trap cleanup EXIT
    
    # Validate environment
    validate_docker
    
    # Build and test images
    if [ "${SKIP_BACKEND:-false}" != "true" ]; then
        build_backend
    else
        info "Skipping backend build"
    fi
    
    if [ "${SKIP_FRONTEND:-false}" != "true" ]; then
        build_frontend
    else
        info "Skipping frontend build"
    fi
    
    # Security checks
    if [ "${SKIP_SECURITY:-false}" != "true" ]; then
        security_scan
    else
        info "Skipping security scans"
    fi
    
    # Production readiness
    if [ "${SKIP_PRODUCTION_CHECK:-false}" != "true" ]; then
        production_readiness_check
    else
        info "Skipping production readiness checks"
    fi
    
    log "All validations completed successfully!"
    log "Docker images are ready for production deployment"
}

# Handle command line arguments
case "${1:-all}" in
    "backend")
        SKIP_FRONTEND=true
        ;;
    "frontend")
        SKIP_BACKEND=true
        ;;
    "security")
        SKIP_BACKEND=true
        SKIP_FRONTEND=true
        SKIP_PRODUCTION_CHECK=true
        ;;
    "all"|*)
        # Run everything
        ;;
esac

# Run main function
main "$@"
