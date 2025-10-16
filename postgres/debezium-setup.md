# PostgreSQL WAL + Debezium CDC Setup

This document provides the complete setup for PostgreSQL with Write-Ahead Logging (WAL) and Debezium Change Data Capture ready for MyKart e-commerce database.

## Current Setup Status ✅

### PostgreSQL Configuration
- **WAL Level**: `logical` (required for Debezium CDC)
- **Archive Mode**: `on` with persistent storage
- **Replication**: Configured for logical replication

### Database Infrastructure
- **Admin Database**: `mydb` - Contains Debezium configuration and infrastructure
- **Application Databases**: Created by individual applications as needed
- **Automatic CDC**: All tables in any database are automatically published via "FOR ALL TABLES"

## Debezium Access Credentials

### Connection Details
- **Host**: `postgres-wal.default.svc.cluster.local` (internal) or LoadBalancer IP (external)
- **Port**: `5432`
- **Admin User**: `admin` / `password123`
- **Debezium User**: `debezium_user` / `debezium_pass`

### Debezium Configuration (in `mydb` database)
- **Replication Slot**: `debezium_mykart_slot`
- **Publication**: `debezium_publication` (covers ALL tables)
- **Plugin**: `pgoutput`

## Debezium Connector Configuration

**Template** for any application database:

```json
{
  "name": "my-app-postgres-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",
    "plugin.name": "pgoutput",
    "database.hostname": "postgres-wal.default.svc.cluster.local",
    "database.port": "5432",
    "database.user": "debezium_user", 
    "database.password": "debezium_pass",
    "database.dbname": "YOUR_APP_DATABASE",
    "database.server.name": "your-app-server",
    "slot.name": "debezium_mykart_slot",
    "publication.name": "debezium_publication",
    "snapshot.mode": "initial",
    "decimal.handling.mode": "double",
    "time.precision.mode": "adaptive_time_microseconds"
  }
}
```

### Key Configuration Notes:
- **database.dbname**: Change to your application's database name
- **database.server.name**: Use a unique identifier for your app
- **table.include.list**: Optional - omit to capture ALL tables (recommended)
- **publication.name**: Use `debezium_publication` (covers ALL TABLES automatically)

## Verification Commands

Check the infrastructure setup:

```sql
-- Connect to mydb to verify Debezium infrastructure
\c mydb
SELECT name, setting FROM pg_settings WHERE name = 'wal_level';
SELECT slot_name, plugin, active FROM pg_replication_slots WHERE slot_name = 'debezium_mykart_slot';
SELECT pubname, puballtables FROM pg_publication WHERE pubname = 'debezium_publication';

-- List all databases (applications will create their own)
SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1');
```

## Key Notes for Debezium Setup

1. **Infrastructure Ready**: PostgreSQL configured for CDC with logical WAL
2. **Publication**: `FOR ALL TABLES` means any table in any database will be captured
3. **Replication Slot**: Single slot can handle multiple databases
4. **Application Independence**: Each app creates its own database/tables
5. **Automatic CDC**: No need to modify publication when new tables are created

## Kafka Topic Structure

Debezium will create topics based on your `database.server.name`:
- `{server-name}.{schema}.{table}`
- Example: `myapp-server.public.users`, `myapp-server.public.orders`

The PostgreSQL setup is now **ready for Debezium CDC integration**! 🚀