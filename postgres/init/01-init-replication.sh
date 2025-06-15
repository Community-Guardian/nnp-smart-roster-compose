#!/bin/bash
set -e

echo "Starting PostgreSQL replication setup..."

# Create replication user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create replication user if not exists
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${POSTGRES_REPLICATION_USER:-replicator}') THEN
            CREATE USER ${POSTGRES_REPLICATION_USER:-replicator} WITH REPLICATION PASSWORD '${POSTGRES_REPLICATION_PASSWORD}';
            RAISE NOTICE 'Created replication user: ${POSTGRES_REPLICATION_USER:-replicator}';
        ELSE
            RAISE NOTICE 'Replication user already exists: ${POSTGRES_REPLICATION_USER:-replicator}';
        END IF;
    END
    \$\$;
    
    -- Grant necessary permissions
    GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_REPLICATION_USER:-replicator};
EOSQL

echo "Configuring pg_hba.conf for replication..."

# Add replication entries to pg_hba.conf
cat >> "${PGDATA}/pg_hba.conf" <<EOF

# Replication connections
host replication ${POSTGRES_REPLICATION_USER:-replicator} 0.0.0.0/0 md5
host replication ${POSTGRES_REPLICATION_USER:-replicator} ::0/0 md5

# Allow replication connections from Docker networks
host replication ${POSTGRES_REPLICATION_USER:-replicator} 172.16.0.0/12 md5
host replication ${POSTGRES_REPLICATION_USER:-replicator} 192.168.0.0/16 md5
host replication ${POSTGRES_REPLICATION_USER:-replicator} 10.0.0.0/8 md5
EOF

echo "Reloading PostgreSQL configuration..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SELECT pg_reload_conf();"

echo "Database initialization completed successfully!"
echo "Replication user: ${POSTGRES_REPLICATION_USER:-replicator}"
echo "pg_hba.conf updated with replication entries"
