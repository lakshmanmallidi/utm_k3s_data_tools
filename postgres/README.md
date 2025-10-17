# PostgreSQL WAL + Debezium CDC Setup

This is a **generic, database-agnostic** PostgreSQL deployment with Debezium Change Data Capture (CDC) capabilities.

## Overview

The deployment creates:
- PostgreSQL 15 with logical WAL replication enabled
- Debezium user with proper (minimal, non-superuser) permissions
- Helper functions for setting up CDC on any application database
- Generic scripts that work with any database

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │    Any App DB    │    │   Debezium      │
│   (WAL + CDC)   │───▶│   (mykart, etc)  │───▶│   Connector     │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Features

✅ **Database Agnostic**: Works with any application database created later
✅ **Secure**: Debezium user has minimal required permissions (not superuser)
✅ **Generic Setup**: Reusable functions and scripts for any database
✅ **Production Ready**: Proper WAL configuration and persistent storage

## Deployment

### 1. Deploy PostgreSQL Infrastructure

```bash
cd postgres
./deploy-postgres-wal.sh
```

This creates:
- PostgreSQL StatefulSet with WAL enabled
- `debezium_user` with replication privileges
- Helper functions for database setup
- LoadBalancer service for external access

### 2. Set up Debezium for Any Application Database

After creating your application database, run:

```bash
cd postgres
./setup-debezium-for-database.sh <your_database_name>
```

This script:
- Grants connect permissions to your database
- Sets up schema-level permissions
- Creates `debezium_publication` for all tables
- Makes debezium_user the publication owner

### 3. Configure Debezium Connector

Use the standard Debezium PostgreSQL connector configuration:

```json
{
  "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
  "database.hostname": "postgres-wal.default.svc.cluster.local",
  "database.port": "5432", 
  "database.user": "debezium_user",
  "database.password": "debezium_pass",
  "database.dbname": "<your_database_name>",
  "publication.name": "debezium_publication"
}
```

## Example: MyKart Database

The `mykart` database deployment automatically uses the generic setup:

```bash
cd mykart/database
./deploy_database.sh  # Automatically calls the generic Debezium setup
```

## Database Permissions

The `debezium_user` has these minimal required permissions:
- `REPLICATION` - for logical replication
- `CREATEDB` - for Debezium operations
- `CONNECT` - on specific databases (granted per database)
- `USAGE` - on public schema (granted per database)
- `SELECT` - on all tables (granted per database)
- Owner of `debezium_publication` (per database)

## Connection Details

- **Admin Access**: `admin` / `password123`
- **Debezium User**: `debezium_user` / `debezium_pass` 
- **Internal**: `postgres-wal.default.svc.cluster.local:5432`
- **External**: `<LoadBalancer-IP>:5432`

## Functions Available

After deployment, these functions are available in the `mydb` database:

### `setup_debezium_for_database(db_name TEXT)`
Grants database-level connect permission to debezium_user.

### `setup_debezium_schema_permissions()` 
Sets up schema permissions and publication within a database context.
This function is created in each target database when needed.

## Security Notes

- The debezium_user is **NOT** a superuser (secure by design)
- Permissions are granted only on databases that explicitly need CDC
- Publications are database-specific and owned by debezium_user
- WAL archiving is enabled for point-in-time recovery

## Troubleshooting

### Check Debezium Setup
```bash
kubectl exec -it postgres-wal-0 -- psql -U admin -d mydb -c "\df setup_debezium*"
```

### Verify User Permissions
```bash
kubectl exec -it postgres-wal-0 -- psql -U admin -d mydb -c "SELECT usename, userepl, usesuper, usecreatedb FROM pg_user WHERE usename = 'debezium_user';"
```

### Test Database Access
```bash
kubectl exec -it postgres-wal-0 -- psql -U debezium_user -d <your_database> -c "SELECT current_user, current_database();"
```

## Adding New Databases

To add CDC support to any new database:

1. Create your application database normally
2. Run: `./setup-debezium-for-database.sh <new_database_name>`
3. Configure your Debezium connector to point to the new database
4. All tables will automatically be included in CDC via the `FOR ALL TABLES` publication

This approach scales to multiple applications and databases without conflicts!