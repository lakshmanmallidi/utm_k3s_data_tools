-- Debezium Setup for MyKart Database
-- This script creates the necessary user, permissions, and publications for Debezium CDC

-- Create Debezium user with replication privileges
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = 'debezium_user') THEN
        CREATE USER debezium_user WITH REPLICATION PASSWORD 'debezium_pass';
    END IF;
END
$$;

-- Grant necessary permissions to debezium_user
GRANT CONNECT ON DATABASE mydb TO debezium_user;
GRANT USAGE ON SCHEMA public TO debezium_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO debezium_user;

-- Create publication for Debezium (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'debezium_publication') THEN
        CREATE PUBLICATION debezium_publication FOR ALL TABLES;
    END IF;
END
$$;

-- Create replication slot for Debezium (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'debezium_mykart_slot') THEN
        PERFORM pg_create_logical_replication_slot('debezium_mykart_slot', 'pgoutput');
    END IF;
END
$$;

-- Verify setup
\echo '=== Debezium Setup Verification ==='
SELECT 'WAL Level: ' || setting as info FROM pg_settings WHERE name = 'wal_level';
SELECT 'Debezium User: ' || usename || ' (replication: ' || CASE WHEN rolreplication THEN 'yes' ELSE 'no' END || ')' as info FROM pg_user WHERE usename = 'debezium_user';
SELECT 'Publication: ' || pubname || ' (all tables: ' || CASE WHEN puballtables THEN 'yes' ELSE 'no' END || ')' as info FROM pg_publication WHERE pubname = 'debezium_publication';
SELECT 'Replication Slot: ' || slot_name || ' (' || plugin || ')' as info FROM pg_replication_slots WHERE slot_name = 'debezium_mykart_slot';
\echo '================================='