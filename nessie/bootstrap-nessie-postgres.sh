#!/bin/bash

# Nessie PostgreSQL Backend Bootstrap Script
# This script initializes PostgreSQL database for Nessie JDBC backend
# It waits for PostgreSQL to be ready and creates necessary database/user/schema

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
POSTGRES_HOST=${POSTGRES_HOST:-postgres-wal}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_ADMIN_USER=${POSTGRES_ADMIN_USER:-admin}
POSTGRES_ADMIN_PASSWORD=${POSTGRES_ADMIN_PASSWORD:-admin_password}
NESSIE_DB=${NESSIE_DB:-nessie}
NESSIE_USER=${NESSIE_USER:-nessie}
NESSIE_PASSWORD=${NESSIE_PASSWORD:-nessie_pass}

print_info "Waiting for PostgreSQL to be ready at ${POSTGRES_HOST}:${POSTGRES_PORT}..."

# Wait for PostgreSQL to accept connections
max_retries=30
retry_count=0
while [ $retry_count -lt $max_retries ]; do
    if PGPASSWORD="$POSTGRES_ADMIN_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_ADMIN_USER" -d postgres -c "SELECT 1" &>/dev/null; then
        print_success "PostgreSQL is ready!"
        break
    fi
    retry_count=$((retry_count + 1))
    if [ $retry_count -ge $max_retries ]; then
        print_error "PostgreSQL did not become ready after $max_retries attempts"
        exit 1
    fi
    echo "Attempt $retry_count/$max_retries - PostgreSQL not ready yet, retrying in 2 seconds..."
    sleep 2
done

# Create Nessie database and user
print_info "Creating Nessie database and user..."

PGPASSWORD="$POSTGRES_ADMIN_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_ADMIN_USER" -d postgres <<EOF
-- Check if database exists, create if not
CREATE DATABASE "$NESSIE_DB" ENCODING 'UTF8';

-- Check if user exists, create if not (need to handle error gracefully)
DO \$\$
BEGIN
  CREATE USER "$NESSIE_USER" WITH PASSWORD '$NESSIE_PASSWORD';
EXCEPTION WHEN duplicate_object THEN
  RAISE NOTICE 'User $NESSIE_USER already exists';
END
\$\$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE "$NESSIE_DB" TO "$NESSIE_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "$NESSIE_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "$NESSIE_USER";

EOF

print_success "Nessie database and user created successfully"

# Verify connection as Nessie user
print_info "Verifying Nessie user can connect to database..."

if PGPASSWORD="$NESSIE_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$NESSIE_USER" -d "$NESSIE_DB" -c "SELECT 1" &>/dev/null; then
    print_success "Nessie user connection verified!"
else
    print_error "Failed to verify Nessie user connection"
    exit 1
fi

print_success "Nessie PostgreSQL backend initialization complete!"
