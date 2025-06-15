# =============================================================================
# DEPLOYMENT RECOVERY SCRIPT (PowerShell)
# Fixes volume mount issues and restarts the deployment
# =============================================================================

function Write-Log {
    param([string]$Message, [string]$Color = "Green")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Write-Warn {
    param([string]$Message)
    Write-Log "WARNING: $Message" -Color "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-Log "ERROR: $Message" -Color "Red"
}

function Write-Info {
    param([string]$Message)
    Write-Log "INFO: $Message" -Color "Blue"
}

Write-Log "🔧 Starting deployment recovery..."

# Step 1: Clean up failed containers and volumes
Write-Log "🧹 Cleaning up failed containers..."
try {
    docker compose down --remove-orphans 2>$null
} catch {
    Write-Info "No containers to clean up"
}

# Step 2: Remove any problematic volumes
Write-Log "🗑️ Removing problematic volumes..."
$problematicVolumes = @(
    "nnp-smart-roster-compose_prometheus_data",
    "nnp-smart-roster-compose_elasticsearch_data", 
    "nnp-smart-roster-compose_backup_volume"
)

foreach ($volume in $problematicVolumes) {
    try {
        docker volume rm $volume 2>$null
        Write-Info "Removed volume: $volume"
    } catch {
        Write-Info "Volume $volume did not exist or could not be removed"
    }
}

# Step 3: Clean up networks
Write-Log "🌐 Cleaning up networks..."
try {
    docker network prune -f 2>$null
} catch {
    Write-Info "Network cleanup completed"
}

# Step 4: Verify .env file exists and is populated
Write-Log "📋 Checking environment configuration..."
if (-not (Test-Path ".env")) {
    Write-Error ".env file not found!"
    if (Test-Path ".env.example") {
        Write-Log "Creating .env from template..."
        Copy-Item ".env.example" ".env"
        Write-Warn "Please edit .env with your actual values before continuing"
        exit 1
    } else {
        Write-Error "No .env.example found either!"
        exit 1
    }
}

# Check critical variables
$criticalVars = @("POSTGRES_PASSWORD", "DJANGO_SECRET_KEY", "REDIS_URL")
$missingVars = @()

$envContent = Get-Content ".env" -Raw
foreach ($var in $criticalVars) {
    if (-not ($envContent -match "^$var=.+" -or $envContent -match "`n$var=.+")) {
        $missingVars += $var
    }
}

if ($missingVars.Count -gt 0) {
    Write-Error "Missing or empty critical environment variables:"
    $missingVars | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Error "Please set these variables in .env before continuing"
    exit 1
}

Write-Log "✅ Environment configuration looks good"

# Step 5: Start essential services first
Write-Log "🚀 Starting essential services..."

Write-Info "Starting database services..."
try {
    docker compose up -d postgres-primary postgres-replica 2>$null
} catch {
    try {
        docker compose up -d postgres-master 2>$null
    } catch {
        try {
            docker compose up -d postgres 2>$null
        } catch {
            Write-Warn "No PostgreSQL service found with expected names"
        }
    }
}

Write-Info "Starting cache services..."
try {
    docker compose up -d redis-master redis-replica 2>$null
} catch {
    try {
        docker compose up -d redis 2>$null
    } catch {
        Write-Warn "No Redis service found with expected names"
    }
}

# Wait for databases to be ready
Write-Log "⏳ Waiting for databases to be ready..."
Start-Sleep -Seconds 10

# Step 6: Start application services
Write-Info "Starting application services..."
try {
    docker compose up -d backend frontend 2>$null
} catch {
    Write-Warn "Backend or frontend services may not be defined"
}

# Step 7: Start supporting services (optional)
Write-Info "Starting supporting services..."
try {
    docker compose up -d nginx 2>$null
} catch {
    Write-Warn "Nginx service not found"
}

# Step 8: Start monitoring services (optional)
Write-Log "🔍 Starting monitoring services (if configured)..."
try {
    docker compose up -d prometheus grafana 2>$null
} catch {
    Write-Info "Monitoring services not started (may be optional)"
}

# Step 9: Show status
Write-Log "📊 Checking deployment status..."
Start-Sleep -Seconds 5
docker compose ps

# Step 10: Health checks
Write-Log "🏥 Running health checks..."

$servicesToCheck = @(
    @{Name="backend"; Port=8000},
    @{Name="frontend"; Port=3000},
    @{Name="nginx"; Port=80}
)

foreach ($service in $servicesToCheck) {
    $healthUrls = @(
        "http://localhost:$($service.Port)/health",
        "http://localhost:$($service.Port)/"
    )
    
    $responding = $false
    foreach ($url in $healthUrls) {
        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                $responding = $true
                break
            }
        } catch {
            # Continue to next URL
        }
    }
    
    if ($responding) {
        Write-Log "✅ $($service.Name) is responding on port $($service.Port)"
    } else {
        Write-Warn "⚠️ $($service.Name) may not be ready on port $($service.Port)"
    }
}

# Step 11: Show logs for debugging
Write-Log "📋 Recent logs (last 20 lines per service):"
Write-Host ""
try {
    docker compose logs --tail=20 2>$null
} catch {
    Write-Warn "Could not retrieve logs"
}

Write-Log "🎉 Deployment recovery completed!"
Write-Host ""
Write-Log "Next steps:"
Write-Log "1. Check 'docker compose ps' to see running services"
Write-Log "2. Review logs with 'docker compose logs -f [service-name]'"
Write-Log "3. Test application endpoints"
Write-Log "4. Monitor resource usage with 'docker stats'"

# Optional: show quick commands
Write-Host ""
Write-Info "Useful commands:"
Write-Host "  docker compose ps                    # Check service status" -ForegroundColor White
Write-Host "  docker compose logs -f backend      # Follow backend logs" -ForegroundColor White
Write-Host "  docker compose logs -f frontend     # Follow frontend logs" -ForegroundColor White
Write-Host "  docker compose down                 # Stop all services" -ForegroundColor White
Write-Host "  docker compose up -d                # Start in background" -ForegroundColor White
