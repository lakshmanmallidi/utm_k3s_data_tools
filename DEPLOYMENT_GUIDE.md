# MyKart Hybrid Architecture - Complete Deployment Guide

This document provides step-by-step instructions for deploying the complete MyKart hybrid architecture from scratch using only deployment scripts.

## Architecture Overview

The MyKart system consists of:
- **PostgreSQL** with WAL logical replication for core business data
- **Kafka** cluster for real-time analytics and message streaming  
- **Debezium CDC Connector** for capturing database changes
- **React + Node.js Web Application** for user interface and analytics events
- **Kafka UI** for monitoring and management

## Prerequisites

- Kubernetes cluster (k3s) running and accessible via `kubectl`
- External LoadBalancer support (UTM k3s setup)
- Node.js and npm installed locally for web application

## Complete Deployment Process

### Step 1: Complete Environment Cleanup

Before starting any deployment, ensure a clean environment:

```bash
# Stop any running web applications
pkill -f "mykart\|node\|react-scripts" || true

# Delete all Kubernetes resources
kubectl delete all --all

# Delete ConfigMaps and PVCs  
kubectl delete configmaps --all && kubectl delete pvc --all

# Verify complete cleanup
kubectl get all,configmaps,pvc
```

**Expected Result**: Only `service/kubernetes` and `configmap/kube-root-ca.crt` should remain.

### Step 2: Deploy PostgreSQL Foundation

PostgreSQL must be deployed first as it provides the data foundation for the entire system.

```bash
cd /Users/lakshmi.mallidi/Documents/utm_k3s_data_tools/postgres
./deploy-postgres-wal.sh
```

**What this deploys**:
- PostgreSQL 16.10 with logical WAL level enabled
- Debezium user (`debezium_user`) with replication permissions
- PostgreSQL publication (`debezium_publication`) configured for ALL TABLES
- LoadBalancer service for external access (192.168.0.25:5432)

**Verification**:
- Pod `postgres-wal-0` should be READY and RUNNING
- WAL level should be `logical`
- Debezium user should exist with proper permissions

### Step 3: Deploy Kafka Cluster

Kafka provides the messaging backbone for both real-time analytics and CDC events.

```bash
cd /Users/lakshmi.mallidi/Documents/utm_k3s_data_tools/kafka
./deploy-kafka.sh
```

**What this deploys**:
- Kafka cluster with KRaft mode (no Zookeeper)
- Dual listeners: internal (PLAINTEXT://kafka:9092) and external (EXTERNAL://192.168.0.25:9092)
- Kafka UI for cluster management
- LoadBalancer services for external access

**Verification**:
```bash
# Wait for Kafka to be ready
kubectl wait --for=condition=ready pod -l app=kafka-kraft --timeout=300s
```

### Step 4: Deploy MyKart Database Schema

Creates the application-specific database and tables with proper Debezium setup.

```bash
cd /Users/lakshmi.mallidi/Documents/utm_k3s_data_tools/mykart/database
./deploy_database.sh
```

**What this creates**:
- `mykart` database with core business tables:
  - `products` (1000 sample products)
  - `orders` (sample order data)
  - `order_line_items` (order details)
- Debezium permissions for CDC on all tables
- Application analytics Kafka topics:
  - `mykart.cart-events`
  - `mykart.clicks`
  - `mykart.impressions`
  - `mykart.page-hits`

**Important**: Answer `y` when prompted to create the database.

### Step 5: Deploy Kafka Connect

Deploys the Kafka Connect framework with Debezium PostgreSQL connector support.

```bash
cd /Users/lakshmi.mallidi/Documents/utm_k3s_data_tools/kafka-connect-deployment
./deploy.sh deploy
```

**What this deploys**:
- Kafka Connect cluster with Debezium PostgreSQL connector
- Kafka Connect internal topics with compact cleanup policy
- LoadBalancer service for external management (192.168.0.25:8080)
- **Fixed behavior**: Only deletes Debezium CDC topics, preserves application topics

**Critical Fix Applied**: The deployment script was updated to only delete Debezium CDC topics (`debezium.mykart.public.*`) and preserve application analytics topics (`mykart.*`).

### Step 6: Deploy Debezium CDC Connector

Creates the actual CDC connector that streams PostgreSQL changes to Kafka.

```bash
cd /Users/lakshmi.mallidi/Documents/utm_k3s_data_tools/kafka-connect-deployment/configs
./deploy-connectors.sh
```

**What this creates**:
- Debezium PostgreSQL connector named `mykart-postgres-debezium-connector`
- CDC topics for core business tables:
  - `debezium.mykart.public.products`
  - `debezium.mykart.public.orders`
  - `debezium.mykart.public.order_line_items`
- Real-time change data capture from PostgreSQL to Kafka

**Verification**:
```bash
# Check connector status - should show RUNNING for both connector and tasks
kubectl exec [kafka-connect-pod] -- wget -qO- http://localhost:8080/connectors/mykart-postgres-debezium-connector/status
```

### Step 7: Deploy Web Application

Deploys the React frontend and Node.js backend with analytics integration.

```bash
cd /Users/lakshmi.mallidi/Documents/utm_k3s_data_tools/mykart/web-app
./deploy_webapp.sh
```

**What this starts**:
- Node.js backend server on port 3001 with:
  - PostgreSQL connection to mykart database
  - Kafka producer for analytics events
  - REST API endpoints for products, orders, analytics
- React development server on port 3000
- Automatic service discovery and connection testing

**Access URLs**:
- React Frontend: http://localhost:3000
- Node.js API: http://localhost:3001

### Final Verification

After complete deployment, verify all components:

```bash
# Check all pods are running
kubectl get pods,svc

# Verify Kafka topics exist
kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# Check Debezium connector status
kubectl exec [kafka-connect-pod] -- wget -qO- http://localhost:8080/connectors/mykart-postgres-debezium-connector/status
```

## Expected Final State

### Kubernetes Resources
```
PODS (All should be RUNNING):
- postgres-wal-0
- kafka-kraft-0  
- kafka-ui-deployment-[id]
- debezium-kafka-connect-[id]

SERVICES (All LoadBalancers should have EXTERNAL-IP):
- postgres-wal-external: 192.168.0.25:5432
- kafka-external: 192.168.0.25:9092
- kafka-ui-service: 192.168.0.25:8090
- debezium-kafka-connect-external: 192.168.0.25:8080
```

### Kafka Topics
```
Application Analytics Topics:
- mykart.cart-events
- mykart.clicks  
- mykart.impressions
- mykart.page-hits

Debezium CDC Topics:
- debezium.mykart.public.products
- debezium.mykart.public.orders
- debezium.mykart.public.order_line_items

Kafka Connect Internal Topics:
- debezium-kafka-connect-configs
- debezium-kafka-connect-offsets
- debezium-kafka-connect-status
```

### Application Status
- **Debezium Connector**: State = "RUNNING", Tasks = "RUNNING"
- **Web Application**: Both React and Node.js servers running
- **Database**: Connected with 1000 products, sample orders
- **Analytics**: Placeholder values (0) for clicks/impressions, real counts for products/orders

## Access Points

- **MyKart Web App**: http://localhost:3000
- **Kafka UI**: http://192.168.0.25:8090  
- **PostgreSQL**: 192.168.0.25:5432 (admin/password123)
- **Kafka Connect REST API**: http://192.168.0.25:8080

## Troubleshooting

### Common Issues and Solutions

1. **Pods stuck in Pending**: Check PVC creation and storage availability
2. **Kafka Connect connector fails**: Verify PostgreSQL replication slot is not locked
3. **Web app can't connect**: Ensure LoadBalancer IPs are accessible (192.168.0.25)
4. **Missing topics**: Check if deployment scripts ran successfully in order

### Reset Individual Components

```bash
# Reset Debezium connector only
kubectl exec [kafka-connect-pod] -- wget --post-data='' --method=DELETE -qO- http://localhost:8080/connectors/mykart-postgres-debezium-connector

# Reset PostgreSQL replication slot
kubectl exec postgres-wal-0 -- psql -U debezium_user -d mykart -c "SELECT pg_drop_replication_slot('debezium_mykart_slot');"

# Reset Kafka Connect deployment
cd /Users/lakshmi.mallidi/Documents/utm_k3s_data_tools/kafka-connect-deployment
./deploy.sh delete
./deploy.sh deploy
```

## Deployment Order Dependency

**CRITICAL**: Components must be deployed in this exact order:
1. PostgreSQL (provides data foundation)
2. Kafka (provides messaging infrastructure) 
3. Database Schema (creates tables and topics)
4. Kafka Connect (provides CDC framework)
5. Debezium Connector (enables actual CDC)
6. Web Application (consumes both systems)

## Architecture Benefits

This deployment creates a hybrid architecture with:
- **PostgreSQL**: ACID transactions for critical business data
- **Kafka**: High-throughput real-time event streaming
- **Debezium CDC**: Automatic change data capture without application changes
- **Dual Analytics**: Real-time events (Kafka) + Historical changes (CDC)
- **External Access**: All services accessible via LoadBalancer for development/testing

## Key Configuration Files

- `postgres/deploy-postgres-wal.sh`: PostgreSQL with Debezium setup
- `kafka/deploy-kafka.sh`: Kafka cluster with external access
- `mykart/database/deploy_database.sh`: Application schema and topics
- `kafka-connect-deployment/deploy.sh`: Kafka Connect framework
- `kafka-connect-deployment/configs/deploy-connectors.sh`: Debezium connector
- `mykart/web-app/deploy_webapp.sh`: React + Node.js application

This guide ensures reliable, repeatable deployments of the complete MyKart hybrid architecture.