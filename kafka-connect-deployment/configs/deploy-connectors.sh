#!/bin/bash

# Deploy Debezium PostgreSQL Connector for MyKart Impressions
# This script deploys the connector configuration to Kafka Connect

set -e

echo "🚀 Deploying MyKart Debezium PostgreSQL Connector"
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Kafka Connect is running
print_status "Checking Kafka Connect status..."
if ! kubectl get pod -l component=kafka-connect &> /dev/null; then
    print_error "Kafka Connect not found! Please deploy kafka-connect first."
    exit 1
fi

# Wait for Kafka Connect to be ready
print_status "Waiting for Kafka Connect to be ready..."
kubectl wait --for=condition=ready pod -l component=kafka-connect --timeout=300s

# Get Kafka Connect pod for internal communication
KAFKA_CONNECT_POD=$(kubectl get pod -l component=kafka-connect -o name | head -1)
if [ -z "$KAFKA_CONNECT_POD" ]; then
    print_error "No Kafka Connect pod found!"
    exit 1
fi

# Extract just the pod name without the "pod/" prefix
POD_NAME_ONLY=$(echo $KAFKA_CONNECT_POD | cut -d'/' -f2)

# Wait a bit more for Kafka Connect service to be fully available
print_status "Waiting for Kafka Connect service to be fully available..."
sleep 30

# Test Kafka Connect availability using internal connectivity with retries
print_status "Testing Kafka Connect connectivity..."
max_attempts=5
attempt=1

while [ $attempt -le $max_attempts ]; do
    print_status "Connectivity test attempt $attempt of $max_attempts..."
    
    if kubectl exec $POD_NAME_ONLY -- wget -qO- http://localhost:8080/connector-plugins &> /dev/null; then
        print_success "Kafka Connect is accessible internally"
        break
    else
        # Show diagnostic information
        print_warning "Connectivity test failed. Pod status:"
        kubectl get pod -l component=kafka-connect
        
        if [ $attempt -eq 3 ]; then
            print_warning "Checking Kafka Connect logs:"
            kubectl logs $POD_NAME_ONLY --tail=10 || true
        fi
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "Cannot reach Kafka Connect after $max_attempts attempts"
        print_error "Final diagnostic information:"
        kubectl describe pod -l component=kafka-connect
        exit 1
    fi
    
    sleep 10
    attempt=$((attempt + 1))
done

print_success "Kafka Connect is accessible internally"

# Check if PostgreSQL is ready
print_status "Verifying PostgreSQL connection..."
if ! kubectl exec postgres-wal-0 -- psql -U admin -d mykart -c "SELECT COUNT(*) FROM products;" > /dev/null 2>&1; then
    print_error "Cannot connect to MyKart PostgreSQL database!"
    exit 1
fi

print_success "PostgreSQL MyKart database is accessible"

# Deploy the MyKart PostgreSQL connector
print_status "Deploying MyKart PostgreSQL Connector..."

# Delete if exists using internal connectivity
kubectl exec $POD_NAME_ONLY -- wget -qO- --post-data='' --header='Content-Type: application/json' \
    "http://localhost:8080/connectors/mykart-postgres-debezium-connector" --method=DELETE &> /dev/null || true

# Copy connector config to pod
print_status "Copying connector configuration..."
if ! kubectl cp mykart-postgres-connector.json $POD_NAME_ONLY:/tmp/; then
    print_error "Failed to copy connector configuration to pod"
    exit 1
fi

# Verify the file was copied
if ! kubectl exec $POD_NAME_ONLY -- ls /tmp/mykart-postgres-connector.json &> /dev/null; then
    print_error "Connector configuration file not found in pod after copy"
    exit 1
fi
print_success "Configuration file copied successfully"

# Deploy the connector using internal connectivity
print_status "Creating connector..."

# First try to create the connector
set +e  # Temporarily disable exit on error
RESPONSE=$(kubectl exec $POD_NAME_ONLY -- wget -qO- --post-file=/tmp/mykart-postgres-connector.json --header="Content-Type: application/json" http://localhost:8080/connectors 2>&1)
EXIT_CODE=$?
set -e  # Re-enable exit on error

# Check if the response indicates success or acceptable conflict
if [ $EXIT_CODE -eq 0 ] && echo "$RESPONSE" | grep -q '"name"'; then
    print_success "MyKart PostgreSQL Connector deployed successfully!"
elif echo "$RESPONSE" | grep -q "409 Conflict"; then
    print_warning "Connector already exists, attempting to update..."
    # Try to get the existing connector info
    EXISTING=$(kubectl exec $POD_NAME_ONLY -- wget -qO- "http://localhost:8080/connectors/mykart-postgres-debezium-connector" 2>/dev/null)
    if echo "$EXISTING" | grep -q '"name"'; then
        print_success "MyKart PostgreSQL Connector already exists and is configured!"
    else
        print_error "Failed to verify existing connector. Response: $RESPONSE"
        exit 1
    fi
else
    print_error "Failed to deploy connector. Exit code: $EXIT_CODE, Response: $RESPONSE"
    exit 1
fi

# Check connector status
print_status "Checking connector status..."
sleep 10

STATUS_RESPONSE=$(kubectl exec $POD_NAME_ONLY -- wget -qO- "http://localhost:8080/connectors/mykart-postgres-debezium-connector/status" 2>/dev/null)
echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "Raw response: $STATUS_RESPONSE"

print_success "🎉 Debezium Connector Deployment Complete!"
echo
print_status "Connector Details:"
echo "  • MyKart Connector: mykart-postgres-debezium-connector"
echo "  • Database: mykart (PostgreSQL)"
echo "  • Access: Internal connectivity via kubectl exec"
echo
print_status "Kafka Topics (CDC and Application):"
echo "  • debezium.mykart.products - for product changes (CDC)"
echo "  • debezium.mykart.orders - for order events (CDC)"
echo "  • debezium.mykart.order_line_items - for order details (CDC)"
echo "  • mykart.impressions - for impression events (App)"
echo "  • mykart.clicks - for click events (App)"
echo "  • mykart.cart-events - for cart events (App)"
echo "  • mykart.page-hits - for page view events (App)"
echo
print_status "Test the setup:"
echo "  1. Insert data into any MyKart table (products, orders, order_line_items)"
echo "  2. Check corresponding Kafka topic (e.g., debezium.mykart.products)"
echo "  3. Monitor connector status:"
echo "     kubectl exec $POD_NAME_ONLY -- wget -qO- http://localhost:8080/connectors/mykart-postgres-debezium-connector/status"
echo
print_status "🔍 Ready to capture all MyKart events via Debezium CDC!"