#!/bin/bash

# Monitor MyKart Kafka Topics for Debezium CDC Events
# This script helps monitor the Kafka topics created by Debezium

echo "📡 MyKart Kafka Topics Monitor"
echo "============================="

KAFKA_POD=$(kubectl get pods -l app=kafka -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$KAFKA_POD" ]; then
    echo "❌ Kafka pod not found! Make sure Kafka is deployed."
    exit 1
fi

echo "🔍 Using Kafka pod: $KAFKA_POD"

# Function to list topics
list_topics() {
    echo
    echo "📋 Available Kafka Topics:"
    kubectl exec $KAFKA_POD -- kafka-topics.sh \
        --bootstrap-server localhost:9092 \
        --list | grep -E "(mykart|impressions)" || echo "No MyKart topics found"
}

# Function to consume from a topic
consume_topic() {
    local topic=$1
    echo
    echo "🎧 Consuming from topic: $topic"
    echo "   (Press Ctrl+C to stop)"
    kubectl exec $KAFKA_POD -- kafka-console-consumer.sh \
        --bootstrap-server localhost:9092 \
        --topic "$topic" \
        --from-beginning \
        --property print.key=true \
        --property print.timestamp=true
}

# Function to get topic info
topic_info() {
    local topic=$1
    echo
    echo "ℹ️  Topic Info: $topic"
    kubectl exec $KAFKA_POD -- kafka-topics.sh \
        --bootstrap-server localhost:9092 \
        --describe \
        --topic "$topic" 2>/dev/null || echo "Topic $topic not found"
}

# Main menu
while true; do
    echo
    echo "📊 MyKart CDC Monitor Menu:"
    echo "1. List all MyKart topics"
    echo "2. Monitor mykart.impressions topic"  
    echo "3. Monitor mykart.clicks topic"
    echo "4. Monitor mykart.cart_events topic"
    echo "5. Monitor mykart.products topic"
    echo "6. Get topic information"
    echo "7. Exit"
    echo
    read -p "Choose an option (1-7): " choice

    case $choice in
        1)
            list_topics
            ;;
        2)
            consume_topic "mykart.impressions"
            ;;
        3)
            consume_topic "mykart.clicks"
            ;;
        4)
            consume_topic "mykart.cart_events"
            ;;
        5)
            consume_topic "mykart.products"
            ;;
        6)
            read -p "Enter topic name: " topic_name
            topic_info "$topic_name"
            ;;
        7)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please choose 1-7."
            ;;
    esac
done