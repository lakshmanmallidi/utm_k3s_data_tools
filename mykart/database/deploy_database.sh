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
    
    # Verify the setup
    echo "📈 Verifying database setup..."
    
    # Count products
    PRODUCT_COUNT=$(kubectl exec postgres-wal-0 -- psql -U admin -d mykart -t -c "SELECT COUNT(*) FROM products;" | tr -d ' ')
    echo "   📦 Products created: $PRODUCT_COUNT"
    
    # List tables
    echo "   📋 Tables created:"
    kubectl exec postgres-wal-0 -- psql -U admin -d mykart -c "\dt" | grep -E "products|orders|order_line_items|cart_events|clicks|impressions|page_hits" | awk '{print "      - " $3}'
    
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