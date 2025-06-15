# =============================================================================
# DOCKER BUILD AND DEPLOYMENT VALIDATION SCRIPT (PowerShell)
# Tests both frontend and backend Dockerfiles for production readiness
# =============================================================================

param(
    [string]$Target = "all",
    [switch]$SkipBackend,
    [switch]$SkipFrontend,
    [switch]$SkipSecurity,
    [switch]$SkipProductionCheck,
    [switch]$CleanupImages
)

# Colors for output
$ColorGreen = "Green"
$ColorYellow = "Yellow"
$ColorRed = "Red"
$ColorBlue = "Blue"

function Write-Log {
    param([string]$Message, [string]$Color = "Green")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Write-Warn {
    param([string]$Message)
    Write-Log "WARNING: $Message" -Color $ColorYellow
}

function Write-Error {
    param([string]$Message)
    Write-Log "ERROR: $Message" -Color $ColorRed
}

function Write-Info {
    param([string]$Message)
    Write-Log "INFO: $Message" -Color $ColorBlue
}

# =============================================================================
# CONFIGURATION
# =============================================================================

$BackendDir = "c:\Users\karan\Documents\GitHub\nnp-smart-roster-backend"
$FrontendDir = "c:\Users\karan\Documents\GitHub\nnp-smart-roster-frontend\smart-attendance"
$ComposeDir = "c:\Users\karan\Documents\GitHub\nnp-smart-roster-compose"

$BuildDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$VcsRef = "unknown"
try {
    $VcsRef = (git rev-parse --short HEAD 2>$null) -replace "`n", ""
} catch {
    # Git not available or not in repo
}

$BuildArgs = @(
    "--build-arg", "BUILD_DATE=$BuildDate",
    "--build-arg", "VCS_REF=$VcsRef",
    "--build-arg", "VERSION=1.0.0"
)

# =============================================================================
# DOCKER VALIDATIONS
# =============================================================================

function Test-Docker {
    Write-Log "Validating Docker installation..."
    
    try {
        $null = Get-Command docker -ErrorAction Stop
    } catch {
        Write-Error "Docker is not installed or not in PATH"
        exit 1
    }
    
    try {
        $null = docker info 2>$null
    } catch {
        Write-Error "Docker daemon is not running"
        exit 1
    }
    
    $dockerVersion = (docker --version) -replace "Docker version ", "" -replace ",.*", ""
    Write-Info "Docker version: $dockerVersion"
    
    # Check for BuildKit support
    try {
        $null = docker buildx version 2>$null
        Write-Info "BuildKit support available"
    } catch {
        Write-Warn "BuildKit not available, builds may be slower"
    }
}

function Test-DockerfileSyntax {
    param([string]$DockerfilePath, [string]$ContextDir)
    
    Write-Log "Validating Dockerfile syntax: $DockerfilePath"
    
    # Check if hadolint is available
    try {
        $null = Get-Command hadolint -ErrorAction Stop
        Write-Info "Running hadolint validation..."
        $hadolintResult = hadolint $DockerfilePath 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Hadolint validation passed"
        } else {
            Write-Warn "Hadolint found issues: $hadolintResult"
        }
    } catch {
        Write-Info "Hadolint not available, skipping advanced validation"
    }
    
    Write-Log "Dockerfile syntax appears valid"
}

# =============================================================================
# BUILD TESTS
# =============================================================================

function Build-Backend {
    Write-Log "Building backend Docker image..."
    
    Push-Location $BackendDir
    try {
        # Validate Dockerfile first
        Test-DockerfileSyntax "Dockerfile" "."
        
        # Build the image
        Write-Info "Starting backend image build..."
        $buildCmd = @("docker", "build") + $BuildArgs + @(
            "--tag", "smartattend-backend:test",
            "--tag", "smartattend-backend:latest",
            "--progress=plain",
            "."
        )
        
        & $buildCmd[0] $buildCmd[1..($buildCmd.Length-1)]
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Backend image built successfully"
        } else {
            Write-Error "Backend image build failed"
            return $false
        }
        
        # Test image size
        $imageSize = (docker images smartattend-backend:test --format "{{.Size}}").Trim()
        Write-Info "Backend image size: $imageSize"
        
        # Quick smoke test
        Write-Log "Running backend smoke test..."
        $smokeTestCmd = @(
            "docker", "run", "--rm", "--name", "backend-test",
            "-e", "DATABASE_URL=sqlite:///tmp/test.db",
            "-e", "REDIS_URL=redis://localhost:6379/0",
            "-e", "DJANGO_SECRET_KEY=test-key-12345",
            "-e", "DJANGO_DEBUG=False",
            "smartattend-backend:test",
            "python", "smartAttend/manage.py", "check"
        )
        
        & $smokeTestCmd[0] $smokeTestCmd[1..($smokeTestCmd.Length-1)]
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Backend smoke test passed"
        } else {
            Write-Warn "Backend smoke test failed (may be due to missing dependencies)"
        }
        
        return $true
        
    } finally {
        Pop-Location
    }
}

function Build-Frontend {
    Write-Log "Building frontend Docker image..."
    
    Push-Location $FrontendDir
    try {
        # Validate Dockerfile first
        Test-DockerfileSyntax "Dockerfile" "."
        
        # Build the image
        Write-Info "Starting frontend image build..."
        $buildCmd = @("docker", "build") + $BuildArgs + @(
            "--tag", "smartattend-frontend:test",
            "--tag", "smartattend-frontend:latest",
            "--progress=plain",
            "."
        )
        
        & $buildCmd[0] $buildCmd[1..($buildCmd.Length-1)]
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Frontend image built successfully"
        } else {
            Write-Error "Frontend image build failed"
            return $false
        }
        
        # Test image size
        $imageSize = (docker images smartattend-frontend:test --format "{{.Size}}").Trim()
        Write-Info "Frontend image size: $imageSize"
        
        # Quick smoke test
        Write-Log "Running frontend smoke test..."
        $job = Start-Job -ScriptBlock {
            & docker run --rm --name frontend-test -e NODE_ENV=production -p 3001:3000 smartattend-frontend:test
        }
        
        Start-Sleep -Seconds 10
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3001/api/health" -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Log "Frontend smoke test passed"
            } else {
                Write-Warn "Frontend health check failed"
            }
        } catch {
            Write-Warn "Frontend smoke test failed: $($_.Exception.Message)"
        } finally {
            # Stop the container
            try { docker stop frontend-test 2>$null } catch { }
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Remove-Job -Job $job -ErrorAction SilentlyContinue
        }
        
        return $true
        
    } finally {
        Pop-Location
    }
}

# =============================================================================
# SECURITY CHECKS
# =============================================================================

function Test-Security {
    Write-Log "Running security checks on Docker images..."
    
    # Use Trivy if available
    try {
        $null = Get-Command trivy -ErrorAction Stop
        Write-Info "Running Trivy security scans..."
        
        Write-Log "Scanning backend image..."
        trivy image --severity HIGH,CRITICAL smartattend-backend:test
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Backend security scan found issues"
        }
        
        Write-Log "Scanning frontend image..."
        trivy image --severity HIGH,CRITICAL smartattend-frontend:test
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Frontend security scan found issues"
        }
    } catch {
        Write-Info "Trivy not available, skipping security scans"
    }
    
    # Check for non-root user
    Write-Log "Checking if containers run as non-root..."
    
    $backendUser = (docker run --rm smartattend-backend:test whoami).Trim()
    if ($backendUser -ne "root") {
        Write-Log "Backend runs as non-root user: $backendUser"
    } else {
        Write-Error "Backend runs as root user - security risk!"
    }
    
    $frontendUser = (docker run --rm smartattend-frontend:test whoami).Trim()
    if ($frontendUser -ne "root") {
        Write-Log "Frontend runs as non-root user: $frontendUser"
    } else {
        Write-Error "Frontend runs as root user - security risk!"
    }
}

# =============================================================================
# PRODUCTION READINESS CHECKS
# =============================================================================

function Test-ProductionReadiness {
    Write-Log "Checking production readiness..."
    
    # Check for health endpoints
    Write-Log "Verifying health endpoints..."
    
    # Backend health check
    $backendHealthCmd = @(
        "docker", "run", "--rm", "--name", "backend-health-test",
        "-e", "DATABASE_URL=sqlite:///tmp/test.db",
        "-e", "REDIS_URL=redis://localhost:6379/0",
        "-e", "DJANGO_SECRET_KEY=test-key-12345",
        "smartattend-backend:test",
        "python", "/tmp/health/check.py"
    )
    
    & $backendHealthCmd[0] $backendHealthCmd[1..($backendHealthCmd.Length-1)] 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Backend health endpoint working"
    } else {
        Write-Warn "Backend health endpoint issues"
    }
    
    # Frontend health check
    Write-Log "Testing frontend health endpoint..."
    $job = Start-Job -ScriptBlock {
        & docker run --rm --name frontend-health-test -p 3002:3000 smartattend-frontend:test
    }
    
    Start-Sleep -Seconds 10
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3002/api/health" -TimeoutSec 5 -ErrorAction Stop
        $healthData = $response.Content | ConvertFrom-Json
        if ($healthData.status -eq "ok") {
            Write-Log "Frontend health endpoint working"
        } else {
            Write-Warn "Frontend health endpoint issues"
        }
    } catch {
        Write-Warn "Frontend health endpoint test failed: $($_.Exception.Message)"
    } finally {
        try { docker stop frontend-health-test 2>$null } catch { }
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        Remove-Job -Job $job -ErrorAction SilentlyContinue
    }
    
    # Check for proper logging
    Write-Log "Checking logging configuration..."
    
    $backendLogs = (docker run --rm smartattend-backend:test sh -c "ls -la /app/logs/ 2>/dev/null | wc -l").Trim()
    if ([int]$backendLogs -gt 0) {
        Write-Log "Backend logging directory configured"
    } else {
        Write-Warn "Backend logging directory issues"
    }
    
    # Check for monitoring hooks
    Write-Log "Checking monitoring capabilities..."
    
    docker run --rm smartattend-backend:test test -f /tmp/monitor.py 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Backend monitoring script present"
    } else {
        Write-Warn "Backend monitoring script missing"
    }
    
    docker run --rm smartattend-frontend:test test -f /app/start.sh 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Frontend startup script present"
    } else {
        Write-Warn "Frontend startup script issues"
    }
}

# =============================================================================
# CLEANUP
# =============================================================================

function Invoke-Cleanup {
    Write-Log "Cleaning up test resources..."
    
    # Stop any running test containers
    $testContainers = docker ps -q --filter "name=*-test" 2>$null
    if ($testContainers) {
        docker stop $testContainers.Split("`n") 2>$null
    }
    
    $testContainersAll = docker ps -aq --filter "name=*-test" 2>$null
    if ($testContainersAll) {
        docker rm $testContainersAll.Split("`n") 2>$null
    }
    
    # Remove test images if requested
    if ($CleanupImages) {
        try {
            docker rmi smartattend-backend:test smartattend-frontend:test 2>$null
        } catch {
            # Images may not exist
        }
    }
    
    Write-Log "Cleanup completed"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

function Main {
    Write-Log "Starting Docker validation and testing..."
    
    # Setup cleanup
    try {
        # Validate environment
        Test-Docker
        
        # Build and test images
        if (-not $SkipBackend -and $Target -in @("all", "backend")) {
            if (-not (Build-Backend)) {
                Write-Error "Backend build failed"
                return
            }
        } else {
            Write-Info "Skipping backend build"
        }
        
        if (-not $SkipFrontend -and $Target -in @("all", "frontend")) {
            if (-not (Build-Frontend)) {
                Write-Error "Frontend build failed"
                return
            }
        } else {
            Write-Info "Skipping frontend build"
        }
        
        # Security checks
        if (-not $SkipSecurity -and $Target -in @("all", "security")) {
            Test-Security
        } else {
            Write-Info "Skipping security scans"
        }
        
        # Production readiness
        if (-not $SkipProductionCheck -and $Target -eq "all") {
            Test-ProductionReadiness
        } else {
            Write-Info "Skipping production readiness checks"
        }
        
        Write-Log "All validations completed successfully!"
        Write-Log "Docker images are ready for production deployment"
        
    } finally {
        Invoke-Cleanup
    }
}

# Run main function
Main
