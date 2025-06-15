#!/bin/bash

# =============================================================================
# ENVIRONMENT VARIABLES VERIFICATION SCRIPT
# Checks that all required environment variables are properly configured
# =============================================================================

echo "🔍 Verifying environment configuration..."
echo "============================================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ ERROR: .env file not found!"
    exit 1
fi

echo "✅ .env file found"

# Source the .env file
set -a
source .env
set +a

echo ""
echo "📋 Environment Variables Summary:"
echo "================================="

# Database Configuration
echo "🗄️  Database Configuration:"
echo "   POSTGRES_HOST: ${POSTGRES_HOST:-NOT_SET}"
echo "   POSTGRES_PORT: ${POSTGRES_PORT:-NOT_SET}"
echo "   POSTGRES_DB: ${POSTGRES_DB:-NOT_SET}"
echo "   POSTGRES_USER: ${POSTGRES_USER:-NOT_SET}"
echo "   POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:+***SET***}"
echo "   DATABASE_URL: ${DATABASE_URL:+***SET***}"

echo ""
echo "🔄 Cache Configuration:"
echo "   REDIS_URL: ${REDIS_URL:-NOT_SET}"

echo ""
echo "🌐 Domain Configuration:"
echo "   DOMAIN: ${DOMAIN:-NOT_SET}"
echo "   SITE_DOMAIN: ${SITE_DOMAIN:-NOT_SET}"
echo "   FRONTEND_URL: ${FRONTEND_URL:-NOT_SET}"
echo "   NEXT_PUBLIC_API_URL: ${NEXT_PUBLIC_API_URL:-NOT_SET}"
echo "   NEXT_PUBLIC_APP_URL: ${NEXT_PUBLIC_APP_URL:-NOT_SET}"

echo ""
echo "🔐 Security Configuration:"
echo "   DJANGO_SECRET_KEY: ${DJANGO_SECRET_KEY:+***SET***}"
echo "   NEXTAUTH_SECRET: ${NEXTAUTH_SECRET:+***SET***}"

echo ""
echo "👤 Admin Configuration:"
echo "   PGADMIN_DEFAULT_EMAIL: ${PGADMIN_DEFAULT_EMAIL:-NOT_SET}"
echo "   PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_DEFAULT_PASSWORD:+***SET***}"

echo ""
echo "📁 FTP Configuration:"
echo "   FTP_USER: ${FTP_USER:-NOT_SET}"
echo "   FTP_PASS: ${FTP_PASS:+***SET***}"  
echo "   PASV_ADDRESS: ${PASV_ADDRESS:-NOT_SET}"

echo ""
echo "🔒 CSRF Configuration:"
echo "   CSRF_TRUSTED_ORIGINS: ${CSRF_TRUSTED_ORIGINS:-NOT_SET}"
echo "   DJANGO_ALLOWED_HOSTS: ${DJANGO_ALLOWED_HOSTS:-NOT_SET}"

# Validation checks
echo ""
echo "✅ Validation Results:"
echo "====================="

ERRORS=0

# Check critical variables
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "❌ POSTGRES_PASSWORD is not set"
    ((ERRORS++))
fi

if [ -z "$DJANGO_SECRET_KEY" ]; then
    echo "❌ DJANGO_SECRET_KEY is not set"
    ((ERRORS++))
fi

if [ -z "$REDIS_URL" ]; then
    echo "❌ REDIS_URL is not set"
    ((ERRORS++))
fi

if [ -z "$NEXT_PUBLIC_API_URL" ]; then
    echo "❌ NEXT_PUBLIC_API_URL is not set"
    ((ERRORS++))
fi

if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL is not set"
    ((ERRORS++))
fi

# Check for common issues
if [[ "$DATABASE_URL" == *"@postgres-master:"* ]]; then
    echo "⚠️  WARNING: DATABASE_URL contains 'postgres-master' but Redis uses 'redis' (not redis-master)"
fi

if [[ "$REDIS_URL" == *"redis-master"* && "$DATABASE_URL" == *"@postgres:"* ]]; then
    echo "⚠️  WARNING: Inconsistent service naming - Redis uses 'redis-master' but Postgres uses 'postgres'"
fi

# Check URL format
if [[ "$NEXT_PUBLIC_API_URL" == *"ngrok"* ]]; then
    echo "ℹ️  INFO: Using ngrok URL for API - ensure tunnel is active"
fi

if [ $ERRORS -eq 0 ]; then
    echo "✅ All critical environment variables are set!"
    echo ""
    echo "🚀 Ready for deployment!"
    echo ""
    echo "Next steps:"
    echo "1. Ensure ngrok tunnel is active: https://calm-deadly-kit.ngrok-free.app/"
    echo "2. Start services: docker compose up -d"
    echo "3. Check logs: docker compose logs -f"
else
    echo "❌ Found $ERRORS critical issues that need to be fixed before deployment"
    exit 1
fi

echo ""
echo "📊 Environment file preview (first 20 lines):"
echo "=============================================="
head -20 .env
