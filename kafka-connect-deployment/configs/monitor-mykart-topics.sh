#!/bin/bash

# MyKart Analytics Topics Monitor
# This script helps monitor the analytics events flowing through Kafka topics

echo "🔍 MyKart Analytics Topics Monitor"
echo "===================================="

# Check if Kafka is running
if ! kubectl get pod kafka-kraft-0 &> /dev/null; then
    echo "❌ Error: Kafka pod 'kafka-kraft-0' not found!"
    echo "Please ensure Kafka is deployed first."
    exit 1
fi

# Function to show topic info
show_topic_info() {
    local topic=$1
    echo "📊 Topic: $topic"
    
        # Check if topic exists
        if kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --list | grep -q "^$topic$"; then
        
        # Show topic details
        kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --describe \
            --topic $topic | grep -E "Topic:|Partition"
        
        # Show message count (approximate)
        echo "   📈 Recent messages (last 10):"
        kubectl exec kafka-kraft-0 -- timeout 5s /opt/kafka/bin/kafka-console-consumer.sh \
            --bootstrap-server localhost:9092 \
            --topic $topic \
            --max-messages 10 \
            --from-beginning 2>/dev/null | head -3 || echo "   No recent messages"
    else
        echo "   ❌ Topic does not exist"
    fi
    echo ""
}

case "${1:-status}" in
    status)
        echo "📋 MyKart Analytics Topics Status:"
        echo ""
        show_topic_info "mykart.cart-events"
        show_topic_info "mykart.clicks"
        show_topic_info "mykart.impressions"
        show_topic_info "mykart.page-hits"
        ;;
        
    monitor)
        topic="${2:-mykart.cart-events}"
        echo "👁️  Monitoring topic: $topic"
        echo "Press Ctrl+C to stop..."
        echo ""
        kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-console-consumer.sh \
            --bootstrap-server localhost:9092 \
            --topic $topic \
            --from-beginning
        ;;
        
    create)
        echo "🚀 Creating MyKart analytics topics..."
        
        topics=("mykart.cart-events" "mykart.clicks" "mykart.impressions" "mykart.page-hits")
        
        for topic in "${topics[@]}"; do
            echo "   Creating topic: $topic"
            kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
                --bootstrap-server localhost:9092 \
                --create --if-not-exists \
                --topic $topic \
                --partitions 3 \
                --replication-factor 1
        done
        
        echo "✅ All topics created successfully!"
        ;;
        
    list)
        echo "📋 All Kafka topics:"
        kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --list | grep -E "(debezium\.mykart|mykart\.)" || echo "No MyKart topics found"
        ;;
        
    *)
        echo "Usage: $0 [status|monitor|create|list] [topic-name]"
        echo ""
        echo "Commands:"
        echo "  status  - Show status of all MyKart analytics topics (default)"
        echo "  monitor - Monitor messages from a specific topic"
        echo "  create  - Create all MyKart analytics topics"
        echo "  list    - List all MyKart topics"
        echo ""
        echo "Examples:"
        echo "  $0 status                    # Show all topics status"
        echo "  $0 monitor mykart.clicks     # Monitor clicks topic"
        echo "  $0 create                    # Create all topics"
        ;;
esac