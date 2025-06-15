#!/bin/bash
# =============================================================================
# SMARTATTEND BACKUP SCRIPT
# Comprehensive backup solution for production environment
# =============================================================================

set -euo pipefail

# Configuration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
S3_BUCKET=${S3_BACKUP_BUCKET:-"smartattend-backups"}
POSTGRES_HOST="postgres-primary"
REDIS_HOST="redis-master"

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "${BACKUP_DIR}/backup.log"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "${BACKUP_DIR}/backup.log"
    exit 1
}

# Create backup directories
mkdir -p "${BACKUP_DIR}/postgres" "${BACKUP_DIR}/redis" "${BACKUP_DIR}/media" "${BACKUP_DIR}/configs"

# =============================================================================
# DATABASE BACKUP
# =============================================================================

backup_postgres() {
    log "Starting PostgreSQL backup..."
    
    # Full database backup
    POSTGRES_BACKUP_FILE="${BACKUP_DIR}/postgres/smartattend_full_${TIMESTAMP}.sql.gz"
    
    PGPASSWORD="${POSTGRES_PASSWORD}" pg_dumpall \
        -h "${POSTGRES_HOST}" \
        -U "${POSTGRES_USER}" \
        --verbose \
        --clean \
        --if-exists \
        | gzip > "${POSTGRES_BACKUP_FILE}"
    
    if [ $? -eq 0 ]; then
        log "PostgreSQL backup completed: ${POSTGRES_BACKUP_FILE}"
        
        # Verify backup integrity
        gunzip -t "${POSTGRES_BACKUP_FILE}"
        if [ $? -eq 0 ]; then
            log "PostgreSQL backup integrity verified"
        else
            error "PostgreSQL backup integrity check failed"
        fi
    else
        error "PostgreSQL backup failed"
    fi
    
    # Individual database backup
    DATABASE_BACKUP_FILE="${BACKUP_DIR}/postgres/smartattend_db_${TIMESTAMP}.sql.gz"
    
    PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump \
        -h "${POSTGRES_HOST}" \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        --verbose \
        --format=custom \
        --compress=9 \
        --file="${DATABASE_BACKUP_FILE%.gz}" \
        && gzip "${DATABASE_BACKUP_FILE%.gz}"
    
    if [ $? -eq 0 ]; then
        log "Individual database backup completed: ${DATABASE_BACKUP_FILE}"
    else
        error "Individual database backup failed"
    fi
    
    # Schema-only backup for quick restore testing
    SCHEMA_BACKUP_FILE="${BACKUP_DIR}/postgres/smartattend_schema_${TIMESTAMP}.sql"
    
    PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump \
        -h "${POSTGRES_HOST}" \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        --schema-only \
        --verbose \
        --file="${SCHEMA_BACKUP_FILE}"
    
    if [ $? -eq 0 ]; then
        log "Schema backup completed: ${SCHEMA_BACKUP_FILE}"
    else
        log "WARNING: Schema backup failed"
    fi
}

# =============================================================================
# REDIS BACKUP
# =============================================================================

backup_redis() {
    log "Starting Redis backup..."
    
    # Create Redis data snapshot
    REDIS_BACKUP_FILE="${BACKUP_DIR}/redis/redis_dump_${TIMESTAMP}.rdb"
    
    # Force Redis to save current state
    redis-cli -h "${REDIS_HOST}" BGSAVE
    
    # Wait for background save to complete
    while [ "$(redis-cli -h "${REDIS_HOST}" LASTSAVE)" == "$(redis-cli -h "${REDIS_HOST}" LASTSAVE)" ]; do
        sleep 1
    done
    
    # Copy the RDB file
    docker cp redis-master:/data/dump.rdb "${REDIS_BACKUP_FILE}"
    
    if [ -f "${REDIS_BACKUP_FILE}" ]; then
        log "Redis backup completed: ${REDIS_BACKUP_FILE}"
        
        # Compress Redis backup
        gzip "${REDIS_BACKUP_FILE}"
        log "Redis backup compressed: ${REDIS_BACKUP_FILE}.gz"
    else
        error "Redis backup failed - file not found"
    fi
    
    # Backup Redis configuration
    REDIS_CONFIG_FILE="${BACKUP_DIR}/redis/redis_config_${TIMESTAMP}.conf"
    redis-cli -h "${REDIS_HOST}" CONFIG GET '*' > "${REDIS_CONFIG_FILE}"
    
    if [ $? -eq 0 ]; then
        log "Redis configuration backup completed: ${REDIS_CONFIG_FILE}"
    else
        log "WARNING: Redis configuration backup failed"
    fi
}

# =============================================================================
# MEDIA FILES BACKUP
# =============================================================================

backup_media() {
    log "Starting media files backup..."
    
    MEDIA_BACKUP_FILE="${BACKUP_DIR}/media/media_files_${TIMESTAMP}.tar.gz"
    
    # Check if media volume exists and has content
    if [ -d "/app/smartAttend/media" ] && [ "$(ls -A /app/smartAttend/media)" ]; then
        tar -czf "${MEDIA_BACKUP_FILE}" \
            -C "/app/smartAttend" \
            media/ \
            --exclude="*.tmp" \
            --exclude="*.temp" \
            --exclude="cache/*"
        
        if [ $? -eq 0 ]; then
            log "Media files backup completed: ${MEDIA_BACKUP_FILE}"
        else
            error "Media files backup failed"
        fi
    else
        log "No media files to backup or directory not found"
        # Create empty marker file
        touch "${BACKUP_DIR}/media/no_media_files_${TIMESTAMP}.marker"
    fi
    
    # Backup static files
    STATIC_BACKUP_FILE="${BACKUP_DIR}/media/static_files_${TIMESTAMP}.tar.gz"
    
    if [ -d "/app/smartAttend/static" ] && [ "$(ls -A /app/smartAttend/static)" ]; then
        tar -czf "${STATIC_BACKUP_FILE}" \
            -C "/app/smartAttend" \
            static/
        
        if [ $? -eq 0 ]; then
            log "Static files backup completed: ${STATIC_BACKUP_FILE}"
        else
            log "WARNING: Static files backup failed"
        fi
    else
        log "No static files to backup"
    fi
}

# =============================================================================
# CONFIGURATION BACKUP
# =============================================================================

backup_configs() {
    log "Starting configuration backup..."
    
    CONFIG_BACKUP_FILE="${BACKUP_DIR}/configs/configs_${TIMESTAMP}.tar.gz"
    
    # Backup all configuration files
    tar -czf "${CONFIG_BACKUP_FILE}" \
        -C "/" \
        etc/nginx/ \
        etc/prometheus/ \
        etc/grafana/ \
        etc/loki/ \
        etc/alertmanager/ \
        etc/pgbouncer/ \
        --exclude="*.key" \
        --exclude="*.pem" \
        --exclude="passwords" \
        2>/dev/null || true
    
    if [ $? -eq 0 ]; then
        log "Configuration backup completed: ${CONFIG_BACKUP_FILE}"
    else
        log "WARNING: Configuration backup had some errors"
    fi
    
    # Backup Docker Compose configuration
    COMPOSE_BACKUP_FILE="${BACKUP_DIR}/configs/docker_compose_${TIMESTAMP}.yml"
    if [ -f "/docker-compose.yml" ]; then
        cp "/docker-compose.yml" "${COMPOSE_BACKUP_FILE}"
        log "Docker Compose configuration backed up: ${COMPOSE_BACKUP_FILE}"
    fi
    
    # Backup environment variables (sanitized)
    ENV_BACKUP_FILE="${BACKUP_DIR}/configs/environment_${TIMESTAMP}.env"
    env | grep -E "^(POSTGRES_|REDIS_|DJANGO_|NGINX_)" | \
        sed 's/=.*PASSWORD.*/=***REDACTED***/g' | \
        sed 's/=.*SECRET.*/=***REDACTED***/g' | \
        sed 's/=.*TOKEN.*/=***REDACTED***/g' > "${ENV_BACKUP_FILE}"
    
    log "Environment configuration backed up (sanitized): ${ENV_BACKUP_FILE}"
}

# =============================================================================
# CLEANUP OLD BACKUPS
# =============================================================================

cleanup_old_backups() {
    log "Cleaning up old backups (retention: ${RETENTION_DAYS} days)..."
    
    # Remove old backup files
    find "${BACKUP_DIR}" -type f -name "*.sql.gz" -mtime +${RETENTION_DAYS} -delete
    find "${BACKUP_DIR}" -type f -name "*.rdb.gz" -mtime +${RETENTION_DAYS} -delete
    find "${BACKUP_DIR}" -type f -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete
    find "${BACKUP_DIR}" -type f -name "*.marker" -mtime +${RETENTION_DAYS} -delete
    
    log "Old backup cleanup completed"
}

# =============================================================================
# CLOUD STORAGE UPLOAD
# =============================================================================

upload_to_s3() {
    if [ -n "${AWS_ACCESS_KEY_ID:-}" ] && [ -n "${AWS_SECRET_ACCESS_KEY:-}" ] && [ -n "${S3_BUCKET}" ]; then
        log "Uploading backups to S3..."
        
        # Upload all backup files from today
        find "${BACKUP_DIR}" -name "*${TIMESTAMP}*" -type f | while read file; do
            s3_key="smartattend/$(date +%Y/%m/%d)/$(basename "$file")"
            
            aws s3 cp "$file" "s3://${S3_BUCKET}/${s3_key}" \
                --storage-class STANDARD_IA \
                --server-side-encryption AES256
            
            if [ $? -eq 0 ]; then
                log "Uploaded to S3: ${s3_key}"
            else
                log "WARNING: Failed to upload to S3: $file"
            fi
        done
        
        log "S3 upload completed"
    else
        log "S3 credentials not configured, skipping cloud upload"
    fi
}

# =============================================================================
# HEALTH CHECK AND NOTIFICATION
# =============================================================================

send_notification() {
    local status=$1
    local message=$2
    
    # Send to monitoring system
    if [ -n "${WEBHOOK_URL:-}" ]; then
        curl -X POST "${WEBHOOK_URL}" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"Backup ${status}: ${message}\", \"username\":\"backup-bot\"}" \
            >/dev/null 2>&1 || true
    fi
    
    # Update Prometheus metrics
    if [ -n "${PROMETHEUS_PUSHGATEWAY:-}" ]; then
        echo "smartattend_backup_status{status=\"${status}\"} $(date +%s)" | \
            curl -X POST "${PROMETHEUS_PUSHGATEWAY}/metrics/job/backup" --data-binary @- \
            >/dev/null 2>&1 || true
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "Starting SmartAttend backup process..."
    
    # Pre-backup health checks
    log "Performing pre-backup health checks..."
    
    # Check PostgreSQL connectivity
    PGPASSWORD="${POSTGRES_PASSWORD}" pg_isready -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}"
    if [ $? -ne 0 ]; then
        error "PostgreSQL is not accessible"
    fi
    
    # Check Redis connectivity
    redis-cli -h "${REDIS_HOST}" ping > /dev/null
    if [ $? -ne 0 ]; then
        error "Redis is not accessible"
    fi
    
    # Check disk space (require at least 10GB free)
    AVAILABLE_SPACE=$(df "${BACKUP_DIR}" | tail -1 | awk '{print $4}')
    if [ "${AVAILABLE_SPACE}" -lt 10485760 ]; then  # 10GB in KB
        error "Insufficient disk space for backup (less than 10GB available)"
    fi
    
    log "Pre-backup health checks passed"
    
    # Perform backups
    backup_postgres
    backup_redis  
    backup_media
    backup_configs
    
    # Post-backup tasks
    cleanup_old_backups
    upload_to_s3
    
    # Calculate backup summary
    BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
    BACKUP_COUNT=$(find "${BACKUP_DIR}" -name "*${TIMESTAMP}*" -type f | wc -l)
    
    log "Backup process completed successfully"
    log "Total backup size: ${BACKUP_SIZE}"
    log "Files created: ${BACKUP_COUNT}"
    
    send_notification "SUCCESS" "Backup completed - Size: ${BACKUP_SIZE}, Files: ${BACKUP_COUNT}"
    
    # Update last backup timestamp for monitoring
    echo "$(date +%s)" > "${BACKUP_DIR}/last_backup_timestamp"
}

# Error handling
trap 'send_notification "FAILED" "Backup script failed with error on line $LINENO"' ERR

# Execute main function
main "$@"
