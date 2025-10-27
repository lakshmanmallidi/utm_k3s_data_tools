#!/bin/bash

set -e

# Function to display usage
show_usage() {
    echo "Usage: $0 [deploy|delete]"
    echo ""
    echo "Commands:"
    echo "  deploy  - Deploy Kafka Connect to k3s cluster"
    echo "  delete  - Remove Kafka Connect from k3s cluster"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 delete"
    exit 1
}

# Function to deploy Kafka Connect
deploy_kafka_connect() {
    echo "🚀 Deploying Kafka Connect to k3s cluster..."

    # Apply ConfigMap first
    echo "📝 Applying ConfigMap..."
    kubectl apply -f configmap.yml

    # Apply Services (ClusterIP + LoadBalancer)
    echo "🌐 Applying Services..."
    kubectl apply -f service.yml

    # Apply Deployment
    echo "⚙️  Applying Deployment..."
    kubectl apply -f deployment.yml

    echo "✅ Deployment complete!"
    echo ""
    
    # Wait for Kafka Connect with better error handling
    wait_for_kafka_connect
    
    echo "🧹 Cleaning up old Kafka topics for fresh start..."
    cleanup_kafka_topics
    
    echo "🔧 Setting up Kafka Connect topics with proper configuration..."
    setup_kafka_connect_topics
    
    echo "🧹 Cleaning up any existing connectors..."
    cleanup_old_connectors
    
    echo ""
    echo "📊 Checking deployment status..."
    kubectl get pods -l component=kafka-connect
    echo ""
    echo "🔗 Service information:"
    kubectl get svc -l component=kafka-connect
    echo ""
    
    # Verify connectivity with proper wait time for Kafka Connect to initialize
    echo "🔍 Verifying Kafka Connect connectivity..."
    local max_attempts=12
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "🔄 Connectivity check attempt $attempt/$max_attempts..."
        
        # Get current pod name each time in case it changes
        local pod_name=$(kubectl get pod -l component=kafka-connect -o name | head -1)
        if [ -z "$pod_name" ]; then
            echo "   No Kafka Connect pod found, waiting..."
        else
            local pod_name_only=$(echo $pod_name | cut -d'/' -f2)
            # Try both curl and wget for better compatibility
            if kubectl exec $pod_name_only -- curl -sf http://localhost:8080/connectors > /dev/null 2>&1 || \
               kubectl exec $pod_name_only -- wget -qO- http://localhost:8080/connectors > /dev/null 2>&1; then
                echo "✅ Kafka Connect is accessible and ready for connectors"
                break
            fi
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo "⚠️  Kafka Connect connectivity check failed after $max_attempts attempts"
            if [ ! -z "$pod_name" ]; then
                local pod_name_only=$(echo $pod_name | cut -d'/' -f2)
                echo "🔍 Pod logs (last 10 lines):"
                kubectl logs $pod_name_only --tail=10 || true
            fi
        else
            echo "   Waiting 10 seconds before next attempt..."
            sleep 10
        fi
        
        attempt=$((attempt + 1))
    done
    
    echo ""
    echo "🌐 Access options:"
    echo "  Internal (ClusterIP): debezium-kafka-connect:8080"
    echo "  External (LoadBalancer): Check EXTERNAL-IP above"
    echo ""
    echo "📍 Health checks:"
    echo "  Internal: kubectl port-forward svc/debezium-kafka-connect 8080:8080"
    echo "           Then: curl http://localhost:8080/connectors"
    echo "  External: curl http://<EXTERNAL-IP>:8080/connectors"
    echo ""
    echo "📋 To check logs: kubectl logs -l component=kafka-connect -f"
    echo ""
    echo "⚖️  To scale: kubectl scale deployment debezium-kafka-connect --replicas=3"
}

# Function to set up Kafka Connect topics with proper configuration
setup_kafka_connect_topics() {
    echo "🔧 Setting up Kafka Connect internal topics with proper configuration..."
    
    # Wait for Kafka to be available
    echo "⏳ Waiting for Kafka to be available..."
    kubectl wait --for=condition=ready pod -l app=kafka-kraft --timeout=300s || true
    
    local kafka_pod=$(kubectl get pod -l app=kafka-kraft -o name | head -1)
    if [ -z "$kafka_pod" ]; then
        echo "⚠️  Kafka pod not found, continuing anyway..."
        return
    fi
    
    local kafka_pod_name=$(echo $kafka_pod | cut -d'/' -f2)
    
    # Define the required topics with compact cleanup policy
    local topics=("debezium-kafka-connect-offsets" "debezium-kafka-connect-configs" "debezium-kafka-connect-status")
    
    for topic in "${topics[@]}"; do
        echo "🔧 Processing topic: $topic"
        
        # Check if topic exists
        if kubectl exec $kafka_pod_name -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list | grep -q "^${topic}$"; then
            echo "   Topic exists, updating cleanup policy..."
            # Update existing topic configuration
            kubectl exec $kafka_pod_name -- /opt/kafka/bin/kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name $topic --alter --add-config cleanup.policy=compact,min.insync.replicas=1 || true
        else
            echo "   Creating topic with compact cleanup policy..."
            # Create topic with correct configuration
            kubectl exec $kafka_pod_name -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic $topic --partitions 1 --replication-factor 1 --config cleanup.policy=compact --config min.insync.replicas=1 || true
        fi
    done
    
    echo "✅ Kafka Connect topics configured successfully"
}

# Function to clean up old Kafka topics
cleanup_kafka_topics() {
    echo "🧹 Cleaning up old Kafka topics..."
    
    # Wait for Kafka to be available
    kubectl wait --for=condition=ready pod -l app=kafka-kraft --timeout=300s || true
    
    local kafka_pod=$(kubectl get pod -l app=kafka-kraft -o name | head -1)
    if [ -z "$kafka_pod" ]; then
        echo "⚠️  Kafka pod not found, skipping topic cleanup..."
        return
    fi
    
    local kafka_pod_name=$(echo $kafka_pod | cut -d'/' -f2)
    
    # Delete Debezium CDC topics to start fresh (NOT application topics)
    local debezium_topics=("debezium.mykart.public.products" "debezium.mykart.public.orders" "debezium.mykart.public.order_line_items")
    
    for topic in "${debezium_topics[@]}"; do
        if kubectl exec $kafka_pod_name -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list | grep -q "^${topic}$"; then
            echo "🗑️  Deleting Debezium CDC topic: $topic"
            kubectl exec $kafka_pod_name -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic $topic || true
        fi
    done
    
    # Note: We preserve application analytics topics (mykart.*) as they are managed by the application
    
    # Delete Kafka Connect internal topics to reset offsets
    local connect_topics=("debezium-kafka-connect-offsets" "debezium-kafka-connect-configs" "debezium-kafka-connect-status")
    
    for topic in "${connect_topics[@]}"; do
        if kubectl exec $kafka_pod_name -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list | grep -q "^${topic}$"; then
            echo "🗑️  Deleting Kafka Connect topic: $topic"
            kubectl exec $kafka_pod_name -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic $topic || true
        fi
    done
    
    echo "✅ Kafka topic cleanup completed"
}

# Function to wait for pod readiness with better error handling
wait_for_kafka_connect() {
    echo "⏳ Waiting for Kafka Connect to be fully ready..."
    
    # Wait for pod to exist first
    local max_wait=60
    local wait_count=0
    while [ $wait_count -lt $max_wait ]; do
        if kubectl get pod -l component=kafka-connect &> /dev/null; then
            break
        fi
        echo "   Waiting for Kafka Connect pod to be created... ($wait_count/$max_wait)"
        sleep 2
        wait_count=$((wait_count + 1))
    done
    
    # Wait for pod to be ready
    kubectl wait --for=condition=ready pod -l component=kafka-connect --timeout=300s || {
        echo "⚠️  Pod readiness timeout, but continuing..."
        return 0
    }
    
    # Give extra time for service initialization
    echo "⏳ Allowing time for service initialization..."
    sleep 15
    
    echo "✅ Kafka Connect should be ready"
}

# Function to clean up old connectors
cleanup_old_connectors() {
    echo "🧹 Cleaning up old connectors..."
    
    # Wait for Kafka Connect to be ready
    echo "⏳ Waiting for Kafka Connect to be ready..."
    kubectl wait --for=condition=ready pod -l component=kafka-connect --timeout=300s || true
    
    # Try to get connector list and clean up
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "🔍 Attempt $attempt: Checking for existing connectors..."
        
        # Use kubectl exec to avoid external network issues
        if kubectl get pod -l component=kafka-connect &> /dev/null; then
            local pod_name=$(kubectl get pod -l component=kafka-connect -o name | head -1)
            if [ ! -z "$pod_name" ]; then
                local pod_name_only=$(echo $pod_name | cut -d'/' -f2)
                local connectors=$(kubectl exec $pod_name_only -- wget -qO- http://localhost:8080/connectors 2>/dev/null || echo "[]")
                
                if [ "$connectors" != "[]" ] && [ "$connectors" != "" ]; then
                    echo "📋 Found existing connectors: $connectors"
                    # Parse and delete each connector
                    echo "$connectors" | grep -o '"[^"]*"' | tr -d '"' | while read connector; do
                        if [ ! -z "$connector" ]; then
                            echo "🗑️  Deleting connector: $connector"
                            kubectl exec $pod_name_only -- wget -qO- --post-data='' --header='Content-Type: application/json' "http://localhost:8080/connectors/$connector" --method=DELETE 2>/dev/null || true
                        fi
                    done
                else
                    echo "✅ No existing connectors found"
                    break
                fi
            fi
        fi
        
        sleep 5
        attempt=$((attempt + 1))
    done
}

# Function to delete Kafka Connect
delete_kafka_connect() {
    echo "🧹 Cleaning up Kafka Connect deployment..."

    # Delete deployment first (no need to cleanup connectors - they'll be deleted with the pod)
    echo "⚙️  Deleting Deployment..."
    kubectl delete -f deployment.yml --ignore-not-found=true

    # Delete services
    echo "🌐 Deleting Services..."
    kubectl delete -f service.yml --ignore-not-found=true

    # Delete configmap
    echo "📝 Deleting ConfigMap..."
    kubectl delete -f configmap.yml --ignore-not-found=true

    echo "✅ Cleanup complete!"
    echo ""
    echo "📊 Remaining resources:"
    kubectl get pods,svc,configmap -l component=kafka-connect
}

# Main script logic
case "${1:-}" in
    deploy)
        deploy_kafka_connect
        ;;
    delete)
        delete_kafka_connect
        ;;
    *)
        echo "❌ Error: Invalid or missing command"
        echo ""
        show_usage
        ;;
esac