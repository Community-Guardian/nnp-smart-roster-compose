# =============================================================================
# ENVIRONMENT VARIABLES VERIFICATION SCRIPT (PowerShell)
# Checks that all required environment variables are properly configured
# =============================================================================

Write-Host "🔍 Verifying environment configuration..." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "❌ ERROR: .env file not found!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ .env file found" -ForegroundColor Green

# Read .env file and create hashtable
$envVars = @{}
Get-Content ".env" | ForEach-Object {
    if ($_ -match "^([^#][^=]+)=(.*)$") {
        $envVars[$matches[1].Trim()] = $matches[2].Trim()
    }
}

Write-Host ""
Write-Host "📋 Environment Variables Summary:" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Database Configuration
Write-Host "🗄️  Database Configuration:" -ForegroundColor Yellow
Write-Host "   POSTGRES_HOST: $($envVars['POSTGRES_HOST'])" -ForegroundColor White
Write-Host "   POSTGRES_PORT: $($envVars['POSTGRES_PORT'])" -ForegroundColor White
Write-Host "   POSTGRES_DB: $($envVars['POSTGRES_DB'])" -ForegroundColor White
Write-Host "   POSTGRES_USER: $($envVars['POSTGRES_USER'])" -ForegroundColor White
$pgPass = if ($envVars['POSTGRES_PASSWORD']) { "***SET***" } else { "NOT_SET" }
Write-Host "   POSTGRES_PASSWORD: $pgPass" -ForegroundColor White
$dbUrl = if ($envVars['DATABASE_URL']) { "***SET***" } else { "NOT_SET" }
Write-Host "   DATABASE_URL: $dbUrl" -ForegroundColor White

Write-Host ""
Write-Host "🔄 Cache Configuration:" -ForegroundColor Yellow
Write-Host "   REDIS_URL: $($envVars['REDIS_URL'])" -ForegroundColor White

Write-Host ""
Write-Host "🌐 Domain Configuration:" -ForegroundColor Yellow
Write-Host "   DOMAIN: $($envVars['DOMAIN'])" -ForegroundColor White
Write-Host "   SITE_DOMAIN: $($envVars['SITE_DOMAIN'])" -ForegroundColor White
Write-Host "   FRONTEND_URL: $($envVars['FRONTEND_URL'])" -ForegroundColor White
Write-Host "   NEXT_PUBLIC_API_URL: $($envVars['NEXT_PUBLIC_API_URL'])" -ForegroundColor White
Write-Host "   NEXT_PUBLIC_APP_URL: $($envVars['NEXT_PUBLIC_APP_URL'])" -ForegroundColor White

Write-Host ""
Write-Host "🔐 Security Configuration:" -ForegroundColor Yellow
$djangoSecret = if ($envVars['DJANGO_SECRET_KEY']) { "***SET***" } else { "NOT_SET" }
Write-Host "   DJANGO_SECRET_KEY: $djangoSecret" -ForegroundColor White
$nextSecret = if ($envVars['NEXTAUTH_SECRET']) { "***SET***" } else { "NOT_SET" }
Write-Host "   NEXTAUTH_SECRET: $nextSecret" -ForegroundColor White

Write-Host ""
Write-Host "👤 Admin Configuration:" -ForegroundColor Yellow
Write-Host "   PGADMIN_DEFAULT_EMAIL: $($envVars['PGADMIN_DEFAULT_EMAIL'])" -ForegroundColor White
$pgAdminPass = if ($envVars['PGADMIN_DEFAULT_PASSWORD']) { "***SET***" } else { "NOT_SET" }
Write-Host "   PGADMIN_DEFAULT_PASSWORD: $pgAdminPass" -ForegroundColor White

Write-Host ""
Write-Host "📁 FTP Configuration:" -ForegroundColor Yellow
Write-Host "   FTP_USER: $($envVars['FTP_USER'])" -ForegroundColor White
$ftpPass = if ($envVars['FTP_PASS']) { "***SET***" } else { "NOT_SET" }
Write-Host "   FTP_PASS: $ftpPass" -ForegroundColor White
Write-Host "   PASV_ADDRESS: $($envVars['PASV_ADDRESS'])" -ForegroundColor White

Write-Host ""
Write-Host "🔒 CSRF Configuration:" -ForegroundColor Yellow
Write-Host "   CSRF_TRUSTED_ORIGINS: $($envVars['CSRF_TRUSTED_ORIGINS'])" -ForegroundColor White
Write-Host "   DJANGO_ALLOWED_HOSTS: $($envVars['DJANGO_ALLOWED_HOSTS'])" -ForegroundColor White

# Validation checks
Write-Host ""
Write-Host "✅ Validation Results:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

$errors = 0

# Check critical variables
$criticalVars = @(
    'POSTGRES_PASSWORD',
    'DJANGO_SECRET_KEY', 
    'REDIS_URL',
    'NEXT_PUBLIC_API_URL',
    'DATABASE_URL'
)

foreach ($var in $criticalVars) {
    if (-not $envVars[$var] -or $envVars[$var] -eq "") {
        Write-Host "❌ $var is not set" -ForegroundColor Red
        $errors++
    }
}

# Check for common issues
if ($envVars['DATABASE_URL'] -and $envVars['DATABASE_URL'].Contains("postgres-master:")) {
    Write-Host "⚠️  WARNING: DATABASE_URL contains 'postgres-master' but should use 'postgres'" -ForegroundColor Yellow
}

if ($envVars['REDIS_URL'] -and $envVars['REDIS_URL'].Contains("redis-master") -and 
    $envVars['DATABASE_URL'] -and $envVars['DATABASE_URL'].Contains("@postgres:")) {
    Write-Host "⚠️  WARNING: Inconsistent service naming - check service names in compose file" -ForegroundColor Yellow
}

# Check URL format
if ($envVars['NEXT_PUBLIC_API_URL'] -and $envVars['NEXT_PUBLIC_API_URL'].Contains("ngrok")) {
    Write-Host "ℹ️  INFO: Using ngrok URL for API - ensure tunnel is active" -ForegroundColor Blue
}

if ($errors -eq 0) {
    Write-Host "✅ All critical environment variables are set!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Ready for deployment!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Ensure ngrok tunnel is active: https://logx.thenyeripoly.ac.ke/" -ForegroundColor White
    Write-Host "2. Start services: docker compose up -d" -ForegroundColor White
    Write-Host "3. Check logs: docker compose logs -f" -ForegroundColor White
} else {
    Write-Host "❌ Found $errors critical issues that need to be fixed before deployment" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📊 Environment file preview (first 20 lines):" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Get-Content ".env" | Select-Object -First 20 | ForEach-Object {
    if ($_ -match "PASSWORD|SECRET|KEY") {
        Write-Host $_.Split('=')[0] + "=***REDACTED***" -ForegroundColor Gray
    } else {
        Write-Host $_ -ForegroundColor White
    }
}
