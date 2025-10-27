# MyKart Kafka Analytics Migration - Deployment Guide

This guide covers the migration of MyKart analytics events from PostgreSQL tables to Kafka topics.

## Topic Naming Convention

The migration implements a clear naming strategy to separate different types of Kafka topics:

- **Debezium CDC Topics**: `debezium.mykart.*`
  - `debezium.mykart.products` - Change events from products table
  - `debezium.mykart.orders` - Change events from orders table  
  - `debezium.mykart.order_line_items` - Change events from order_line_items table
  - `debezium.mykart.db.history` - Debezium database history topic

- **Application Event Topics**: `mykart.*`
  - `mykart.cart-events` - User cart interactions
  - `mykart.clicks` - User click tracking
  - `mykart.impressions` - Product view impressions
  - `mykart.page-hits` - Page navigation events

This separation makes it easy to:
- Route different event types to appropriate consumers
- Apply different retention policies (CDC vs analytics events)
- Scale processing independently for each event type
- Monitor and troubleshoot specific event flows

## Changes Summary

### ✅ What Changed
- **Analytics Events** moved from PostgreSQL to Kafka:
  - `cart_events` table → `mykart.cart-events` topic
  - `clicks` table → `mykart.clicks` topic  
  - `impressions` table → `mykart.impressions` topic
  - `page_hits` table → `mykart.page-hits` topic

- **Core Data** remains in PostgreSQL:
  - `products` table (unchanged)
  - `orders` table (unchanged)
  - `order_line_items` table (unchanged)

### 🔄 Updated Components
1. **Database Schema** (`init_mykart_db.sql`) - Removed analytics tables
2. **Web Application** (`server.js`) - Added Kafka producer for events
3. **Debezium Connector** - Only captures core tables now
4. **Package Dependencies** - Added `kafkajs` library

## Deployment Steps

### 1. Prerequisites
Ensure these are deployed and running:
```bash
# Check Kafka
kubectl get pod kafka-kraft-0

# Check PostgreSQL  
kubectl get pod postgres-wal-0
```

### 2. Deploy Updated Database
```bash
cd mykart/database
./deploy_database.sh
```
This will:
- ✅ Recreate database with only core tables
- ✅ Create Kafka topics for analytics events
- ✅ Setup Debezium permissions

### 3. Update Web Application Dependencies
```bash
cd mykart/web-app
npm install
# This will install the new kafkajs dependency
```

### 4. Update Debezium Connector
```bash
cd kafka-connect-deployment/configs

# Delete existing connector
curl -X DELETE http://localhost:8083/connectors/mykart-postgres-debezium-connector

# Deploy updated connector (only core tables)
curl -X POST \
  -H "Content-Type: application/json" \
  --data @mykart-postgres-connector.json \
  http://localhost:8083/connectors
```

### 5. Deploy Updated Web Application
```bash
cd mykart/web-app
# Update environment variables if needed
export KAFKA_BROKERS="kafka.default.svc.cluster.local:9092"

# Start the application
npm start
```

## Verification

### 1. Check Kafka Topics
```bash
# Use the monitoring script
cd kafka-connect-deployment/configs
./monitor-mykart-topics.sh status
```

### 2. Test Analytics Events
```bash
# Monitor cart events in real-time
./monitor-mykart-topics.sh monitor mykart.cart-events

# In another terminal, trigger some events via API:
curl -X POST http://localhost:3001/api/cart/add \
  -H "Content-Type: application/json" \
  -d '{"productId": 1, "quantity": 2}'
```

### 3. Verify Database Tables
```bash
kubectl exec -it postgres-wal-0 -- psql -U admin -d mykart -c "\\dt"
# Should only show: products, orders, order_line_items
```

### 4. Check Debezium Connector
```bash
curl -X GET http://localhost:8083/connectors/mykart-postgres-debezium-connector/status
# Should show healthy status and only 3 tasks (for 3 tables)
```

## Data Flow Overview

### Before (PostgreSQL Only)
```
Web App → PostgreSQL Tables
    ├── products
    ├── orders  
    ├── order_line_items
    ├── cart_events      ❌ 
    ├── clicks           ❌
    ├── impressions      ❌
    └── page_hits        ❌
```

### After (Hybrid Architecture)
```
Web App → PostgreSQL (Core Data) + Kafka (Analytics)
    
PostgreSQL:                 Kafka Topics:
├── products               ├── mykart.cart-events
├── orders                 ├── mykart.clicks  
└── order_line_items       ├── mykart.impressions
                          └── mykart.page-hits
```

## Benefits

### ✅ Advantages
- **Real-time Analytics**: Events stream immediately to consumers
- **Scalability**: Kafka handles high-volume analytics events better
- **Decoupling**: Analytics processing doesn't impact transactional database
- **Durability**: Kafka provides configurable retention and replication
- **Multiple Consumers**: Different systems can process the same events

### ⚠️ Considerations  
- **Cart State**: Currently simplified (no persistent cart without database)
- **Analytics Queries**: Need stream processing instead of SQL queries
- **Complexity**: Additional infrastructure component (Kafka)

## Monitoring & Troubleshooting

### Monitor Kafka Topics
```bash
# Check topic status
./monitor-mykart-topics.sh status

# Monitor specific topic
./monitor-mykart-topics.sh monitor mykart.clicks

# List all topics
./monitor-mykart-topics.sh list
```

### Application Logs
```bash
# Web application logs (check for Kafka connection)
kubectl logs deployment/mykart-webapp -f

# Look for: "✅ Connected to Kafka"
```

### Kafka Health Check
```bash
# Test Kafka connectivity
kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-broker-api-versions.sh \
  --bootstrap-server localhost:9092
```

## Rollback Plan

If needed, you can rollback to PostgreSQL-only analytics:

1. Revert database schema (restore analytics tables)
2. Update web application to use PostgreSQL 
3. Update Debezium connector to capture all tables
4. Remove Kafka dependencies

The core application functionality (products, orders) is unaffected during rollback.