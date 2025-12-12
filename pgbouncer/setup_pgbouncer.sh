#!/bin/bash
# =============================================================================
# PgBouncer Setup Script
# Generates proper configuration files with MD5 hashed passwords
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}==============================================================================${NC}"
echo -e "${GREEN}PgBouncer Configuration Setup${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo ""

# Load environment variables
if [ -f .env ]; then
    source .env
    echo -e "${GREEN}✓ Loaded .env file${NC}"
else
    echo -e "${RED}✗ .env file not found!${NC}"
    exit 1
fi

# Set defaults
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-user@12345}
POSTGRES_DB=${POSTGRES_DB:-agex_db}

# Create pgbouncer directory
mkdir -p pgbouncer
echo -e "${GREEN}✓ Created pgbouncer directory${NC}"

# Function to generate MD5 password for PostgreSQL
generate_md5_password() {
    local username=$1
    local password=$2
    echo -n "md5$(echo -n "${password}${username}" | md5sum | cut -d' ' -f1)"
}

# Generate MD5 passwords
POSTGRES_MD5=$(generate_md5_password "$POSTGRES_USER" "$POSTGRES_PASSWORD")
REPLICATOR_MD5=$(generate_md5_password "replicator" "$POSTGRES_PASSWORD")

echo -e "${YELLOW}Generating configuration files...${NC}"

# =============================================================================
# Create pgbouncer.ini
# =============================================================================

cat > pgbouncer/pgbouncer.ini << EOF
[databases]
; Database connections - specific database
${POSTGRES_DB} = host=postgres-primary port=5432 dbname=${POSTGRES_DB}

; Fallback for any database
* = host=postgres-primary port=5432

[pgbouncer]
; =============================================================================
; LISTEN SETTINGS
; =============================================================================
listen_addr = *
listen_port = 6432
unix_socket_dir =

; =============================================================================
; AUTHENTICATION
; =============================================================================
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt

; =============================================================================
; POOL SETTINGS (Session mode for Django compatibility)
; =============================================================================
pool_mode = session
max_client_conn = 2000
default_pool_size = 50
min_pool_size = 10
reserve_pool_size = 10
reserve_pool_timeout = 3
max_db_connections = 100
max_user_connections = 100

; =============================================================================
; SERVER CONNECTION SETTINGS
; =============================================================================
server_reset_query = DISCARD ALL
server_reset_query_always = 0
server_check_delay = 30
server_check_query = select 1
server_lifetime = 3600
server_idle_timeout = 600
server_connect_timeout = 15
server_login_retry = 15

; =============================================================================
; CLIENT CONNECTION SETTINGS
; =============================================================================
client_idle_timeout = 600
client_login_timeout = 60
query_timeout = 0
query_wait_timeout = 120
autodb_idle_timeout = 3600

; =============================================================================
; ADMIN SETTINGS
; =============================================================================
admin_users = ${POSTGRES_USER}
stats_users = ${POSTGRES_USER}

; =============================================================================
; LOGGING
; =============================================================================
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
stats_period = 60
verbose = 0

; =============================================================================
; PERFORMANCE TUNING
; =============================================================================
ignore_startup_parameters = extra_float_digits,application_name
application_name_add_host = 1
cancel_timeout = 10

; Resource limits
pkt_buf = 4096
max_packet_size = 2147483647
tcp_socket_buffer = 0
tcp_keepalive = 1
tcp_keepcnt = 9
tcp_keepidle = 7200
tcp_keepintvl = 75
EOF

echo -e "${GREEN}✓ Created pgbouncer/pgbouncer.ini${NC}"

# =============================================================================
# Create userlist.txt with MD5 hashed passwords
# =============================================================================

cat > pgbouncer/userlist.txt << EOF
"${POSTGRES_USER}" "${POSTGRES_MD5}"
"replicator" "${REPLICATOR_MD5}"
EOF

echo -e "${GREEN}✓ Created pgbouncer/userlist.txt with MD5 hashed passwords${NC}"

# Set proper permissions
chmod 600 pgbouncer/userlist.txt
chmod 644 pgbouncer/pgbouncer.ini

echo -e "${GREEN}✓ Set proper file permissions${NC}"

# =============================================================================
# Test the configuration
# =============================================================================

echo ""
echo -e "${YELLOW}Configuration Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Database: ${GREEN}${POSTGRES_DB}${NC}"
echo -e "User: ${GREEN}${POSTGRES_USER}${NC}"
echo -e "Pool Mode: ${GREEN}session${NC} (Django compatible)"
echo -e "Max Client Connections: ${GREEN}2000${NC}"
echo -e "Default Pool Size: ${GREEN}50${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${GREEN}==============================================================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Review the generated files in pgbouncer/ directory"
echo "2. Update your docker-compose.yml to mount these files"
echo "3. Restart PgBouncer: docker-compose restart pgbouncer"
echo "4. Test connection: docker-compose exec pgbouncer psql -h localhost -p 6432 -U ${POSTGRES_USER} -d ${POSTGRES_DB}"
echo ""
echo -e "${YELLOW}Verification Commands:${NC}"
echo "• Check PgBouncer logs: docker-compose logs -f pgbouncer"
echo "• Check PgBouncer status: docker-compose exec pgbouncer psql -h localhost -p 6432 -U ${POSTGRES_USER} -d pgbouncer -c 'SHOW POOLS;'"
echo "• Test database connection: docker-compose exec pgbouncer psql -h localhost -p 6432 -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c 'SELECT 1;'"
echo ""