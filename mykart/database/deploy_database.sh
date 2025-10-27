#!/bin/bash

# MyKart Database Deployment Script
# This script will drop the existing database and recreate it with sample data

echo "🗄️  MyKart Database Deployment"
echo "================================"

# Check if PostgreSQL pod is running
echo "Checking PostgreSQL connection..."
if ! kubectl get pod postgres-wal-0 &> /dev/null; then
    echo "❌ Error: PostgreSQL pod 'postgres-wal-0' not found!"
    echo "Please ensure PostgreSQL WAL is deployed first."
    exit 1
fi

# Test PostgreSQL connection
echo "Testing database connection..."
if ! kubectl exec postgres-wal-0 -- pg_isready -U admin -d mydb > /dev/null 2>&1; then
    echo "❌ Error: Cannot connect to PostgreSQL!"
    echo "Please check if PostgreSQL is running properly."
    exit 1
fi

echo "✅ PostgreSQL connection successful!"

# Copy SQL file to PostgreSQL pod
echo "📁 Copying database initialization script..."
kubectl cp init_mykart_db.sql postgres-wal-0:/tmp/

# Execute the SQL script
echo "🚀 Executing database initialization..."
echo "⚠️  This will drop the existing 'mykart' database if it exists!"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# Run the initialization script
echo "📊 Creating MyKart database and tables..."
kubectl exec -i postgres-wal-0 -- psql -U admin -d postgres < /dev/stdin << 'EOF'
\i /tmp/init_mykart_db.sql
EOF

if [ $? -eq 0 ]; then
    echo "✅ Database initialization completed successfully!"
    
    # Setup Debezium permissions for mykart database using generic setup script
    echo "🔐 Setting up Debezium permissions for MyKart database..."
    
    # Use the generic Debezium setup script
    if [ -f "../../postgres/setup-debezium-for-database.sh" ]; then
        ../../postgres/setup-debezium-for-database.sh mykart
    else
        # Fallback to direct commands if script not found
        echo "📡 Using direct setup commands..."
        kubectl exec postgres-wal-0 -- psql -U admin -d mydb -c "SELECT setup_debezium_for_database('mykart');"
        kubectl exec postgres-wal-0 -- psql -U admin -d mykart -c "SELECT setup_debezium_schema_permissions();"
        echo "✅ Debezium setup completed"
    fi
    
    # Verify the setup
    echo "📈 Verifying database setup..."
    
    # Count products
    PRODUCT_COUNT=$(kubectl exec postgres-wal-0 -- psql -U admin -d mykart -t -c "SELECT COUNT(*) FROM products;" | tr -d ' ')
    echo "   📦 Products created: $PRODUCT_COUNT"
    
    # List tables
    echo "   📋 Tables created:"
    kubectl exec postgres-wal-0 -- psql -U admin -d mykart -c "\dt" | grep -E "products|orders|order_line_items" | awk '{print "      - " $3}'
    
    
    # Create Kafka topics for analytics events
    echo "🚀 Managing Kafka topics for analytics events..."
    
    # Check if Kafka is running
    if kubectl get pod kafka-kraft-0 &> /dev/null; then
        echo "   🧹 Cleaning up any existing application MyKart topics..."
        
        # Get list of existing application MyKart topics (not Debezium CDC topics)
        EXISTING_APP_TOPICS=$(kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --list 2>/dev/null | grep "^mykart\." | grep -v "^debezium\.mykart" || echo "")
            
        if [ ! -z "$EXISTING_APP_TOPICS" ]; then
            echo "   🗑️  Deleting existing application topics..."
            for topic in $EXISTING_APP_TOPICS; do
                echo "      Deleting: $topic"
                kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
                    --bootstrap-server localhost:9092 \
                    --delete --topic "$topic" >/dev/null 2>&1
            done
            echo "   ✅ Application topic cleanup completed"
        else
            echo "   ℹ️  No existing application MyKart topics found"
        fi
        
        # Check if Debezium CDC topics exist
        CDC_TOPICS=$(kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --list 2>/dev/null | grep "^debezium\.mykart" || echo "")
            
        if [ ! -z "$CDC_TOPICS" ]; then
            echo "   ℹ️  Preserving existing Debezium CDC topics:"
            for topic in $CDC_TOPICS; do
                echo "      Preserved: $topic"
            done
        fi
        
        echo "   📡 Creating analytics topics with new naming convention..."
        
        # Create topics for analytics events (application topics)
        kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --create \
            --topic mykart.cart-events \
            --partitions 3 \
            --replication-factor 1 \
            --config cleanup.policy=delete \
            --config retention.ms=604800000
            
        kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --create \
            --topic mykart.clicks \
            --partitions 3 \
            --replication-factor 1 \
            --config cleanup.policy=delete \
            --config retention.ms=604800000
            
        kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --create \
            --topic mykart.impressions \
            --partitions 3 \
            --replication-factor 1 \
            --config cleanup.policy=delete \
            --config retention.ms=604800000
            
        kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --create \
            --topic mykart.page-hits \
            --partitions 3 \
            --replication-factor 1 \
            --config cleanup.policy=delete \
            --config retention.ms=604800000
            
        echo "   ✅ Analytics topics created successfully!"
        
        # List created topics
        echo "   📋 Application analytics topics:"
        kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --list | grep "mykart\." | grep -v "debezium" | sort | awk '{print "      - " $1}'
            
        echo "   ℹ️  Note: Debezium CDC topics will be created automatically when connector starts"
    else
        echo "   ⚠️  Kafka not found - skipping topic creation"
        echo "   ℹ️  Make sure to deploy Kafka and run this script again to create topics"
    fi

    echo ""
    echo "🎉 MyKart database is ready!"
    echo ""
    echo "📝 Database Connection Info:"
    echo "   Database: mykart"
    echo "   Username: admin"
    echo "   Password: password123"
    echo "   Internal: postgres:5432"
    echo "   External: $(kubectl get svc postgres-wal-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):5432"
    echo ""
    echo "🔍 Quick test:"
    echo "   kubectl exec -it postgres-wal-0 -- psql -U admin -d mykart -c \"SELECT name, price FROM products LIMIT 5;\""
    
else
    echo "❌ Database initialization failed!"
    echo "Check the logs above for error details."
    exit 1
fi