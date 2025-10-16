#!/bin/bash

# PostgreSQL with WAL and Debezium Setup Deployment Script
# This script deploys PostgreSQL with WAL archiving and Debezium CDC support
# Including MyKart e-commerce database with 1000+ products

set -e

echo "� Starting PostgreSQL WAL + Debezium Setup Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if connected to k3s cluster
print_status "Checking Kubernetes cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Not connected to Kubernetes cluster"
    exit 1
fi

print_success "Connected to Kubernetes cluster"

# Function to wait for pod to be ready
wait_for_pod() {
    local pod_name=$1
    local timeout=${2:-300}
    
    print_status "Waiting for pod $pod_name to be ready (timeout: ${timeout}s)..."
    
    if kubectl wait --for=condition=Ready pod/$pod_name --timeout=${timeout}s; then
        print_success "Pod $pod_name is ready"
        return 0
    else
        print_error "Pod $pod_name failed to become ready within ${timeout}s"
        return 1
    fi
}

# Clean up existing deployment if exists
print_status "Cleaning up existing PostgreSQL deployment..."
kubectl delete statefulset postgres-wal --ignore-not-found=true
kubectl delete configmap postgres-wal-config postgres-init-scripts --ignore-not-found=true
kubectl delete service postgres-wal --ignore-not-found=true
kubectl delete pvc --selector=app=postgres-wal --ignore-not-found=true

print_success "Cleanup completed"

# Wait a bit for cleanup to complete
sleep 5

# Deploy PostgreSQL StatefulSet with WAL and Debezium support
print_status "Deploying PostgreSQL StatefulSet with WAL and Debezium configuration..."
kubectl apply -f postgres-wal-statefulset.yaml

if [ $? -eq 0 ]; then
    print_success "PostgreSQL StatefulSet deployed successfully"
else
    print_error "Failed to deploy PostgreSQL StatefulSet"
    exit 1
fi

# Wait for PostgreSQL pod to be ready
if wait_for_pod "postgres-wal-0" 300; then
    print_success "PostgreSQL is running and ready"
else
    print_error "PostgreSQL failed to start"
    kubectl logs postgres-wal-0 --tail=50
    exit 1
fi

# Create PostgreSQL service
print_status "Creating PostgreSQL LoadBalancer service..."
kubectl apply -f postgres-wal-service.yaml

if [ $? -eq 0 ]; then
    print_success "PostgreSQL service created successfully"
else
    print_error "Failed to create PostgreSQL service"
    exit 1
fi

# Wait a bit for initialization scripts to complete
print_status "Waiting for initialization scripts to complete..."
sleep 20

# Note: MyKart database tables will be initialized when the MyKart app is deployed
print_status "PostgreSQL infrastructure is ready for application deployments..."

# Verify Debezium setup
print_status "Verifying Debezium setup..."
kubectl exec postgres-wal-0 -- psql -U admin -d mydb -c "
SELECT 
    'WAL Level: ' || setting as verification 
FROM pg_settings 
WHERE name = 'wal_level'
UNION ALL
SELECT 
    'Debezium User: ' || CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'NOT FOUND' END 
FROM pg_user 
WHERE usename = 'debezium_user'
UNION ALL
SELECT 
    'Publication: ' || CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'NOT FOUND' END 
FROM pg_publication 
WHERE pubname = 'debezium_publication'
UNION ALL
SELECT 
    'Replication Slot: ' || CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'NOT FOUND' END 
FROM pg_replication_slots 
WHERE slot_name = 'debezium_mykart_slot';
"

# Get service information
print_status "Getting service information..."
kubectl get svc postgres-wal -o wide

# Show pod status
print_status "PostgreSQL pod status:"
kubectl get pods -l app=postgres-wal -o wide

# Verify basic database setup
print_status "Verifying PostgreSQL database setup..."
kubectl exec postgres-wal-0 -- psql -U admin -d mydb -c "
SELECT 'Database mydb ready' as status
UNION ALL
SELECT 'Total databases: ' || COUNT(*) FROM pg_database WHERE datname NOT IN ('template0', 'template1');
"

print_success "🎉 PostgreSQL WAL + Debezium Setup Deployment Complete!"
echo
print_status "Summary:"
echo "  • PostgreSQL 15 with logical WAL level for Debezium CDC"
echo "  • WAL archiving enabled with persistent storage"  
echo "  • Debezium user and replication slot created"
echo "  • Ready for any application database initialization"
echo "  • Publication configured to capture changes from any future tables"
echo
print_status "Connection Details:"
echo "  • Database: mydb (admin database)"  
echo "  • Admin User: admin / password123"
echo "  • Debezium User: debezium_user / debezium_pass"
echo "  • Replication Slot: debezium_mykart_slot"
echo "  • Publication: debezium_publication (FOR ALL TABLES)"
echo "  • External Access: $(kubectl get svc postgres-wal-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'Check LoadBalancer service'):5432"
echo
print_status "Next Steps:"
echo "  1. Deploy your applications (they can create their own databases/tables)"
echo "  2. Configure Debezium connector to point to application databases"  
echo "  3. All tables created will automatically be included in CDC via 'FOR ALL TABLES' publication"
echo
print_success "Ready for Debezium connector configuration!"