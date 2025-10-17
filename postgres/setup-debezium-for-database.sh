#!/bin/bash

# Generic Debezium Setup Script for Any Database
# Usage: ./setup-debezium-for-database.sh <database_name>

set -e

DATABASE_NAME="$1"

if [ -z "$DATABASE_NAME" ]; then
    echo "❌ Error: Database name is required"
    echo "Usage: $0 <database_name>"
    exit 1
fi

echo "🔐 Setting up Debezium permissions for database: $DATABASE_NAME"

# Check if PostgreSQL pod is running
if ! kubectl get pod postgres-wal-0 &> /dev/null; then
    echo "❌ Error: PostgreSQL pod 'postgres-wal-0' not found!"
    echo "Please ensure PostgreSQL WAL is deployed first."
    exit 1
fi

# Test PostgreSQL connection
if ! kubectl exec postgres-wal-0 -- pg_isready -U admin -d mydb > /dev/null 2>&1; then
    echo "❌ Error: Cannot connect to PostgreSQL!"
    exit 1
fi

echo "✅ PostgreSQL connection successful!"

# Grant database-level permissions using the function from mydb
echo "📡 Granting database connect permissions..."
kubectl exec postgres-wal-0 -- psql -U admin -d mydb -c "SELECT setup_debezium_for_database('${DATABASE_NAME}');"

# Setup schema-level permissions within target database
echo "🔧 Setting up schema permissions and publication..."

# First, create the function in the target database (since functions are database-specific)
kubectl exec postgres-wal-0 -- psql -U admin -d "${DATABASE_NAME}" -c "
CREATE OR REPLACE FUNCTION setup_debezium_schema_permissions() 
RETURNS VOID AS \$func\$
BEGIN
    -- Grant schema usage
    GRANT USAGE ON SCHEMA public TO debezium_user;
    
    -- Grant select on all existing tables
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium_user;
    
    -- Grant select on all future tables
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO debezium_user;
    
    -- Create publication for this database if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'debezium_publication') THEN
        CREATE PUBLICATION debezium_publication FOR ALL TABLES;
    END IF;
    
    -- Change publication owner to debezium_user for proper permissions
    ALTER PUBLICATION debezium_publication OWNER TO debezium_user;
    
    RAISE NOTICE 'Debezium permissions setup completed for current database';
END;
\$func\$ LANGUAGE plpgsql;
"

# Then execute the function
kubectl exec postgres-wal-0 -- psql -U admin -d "${DATABASE_NAME}" -c "SELECT setup_debezium_schema_permissions();"

echo "✅ Debezium setup completed for database: $DATABASE_NAME"
echo ""
echo "📋 Summary:"
echo "  • Database: $DATABASE_NAME"
echo "  • Debezium User: debezium_user has full access"
echo "  • Publication: debezium_publication (FOR ALL TABLES)"
echo "  • Ready for Debezium connector configuration"
echo ""
echo "🔍 Verify access:"
echo "  kubectl exec -it postgres-wal-0 -- psql -U debezium_user -d $DATABASE_NAME -c 'SELECT current_user, current_database();'"