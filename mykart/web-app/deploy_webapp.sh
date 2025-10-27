#!/bin/bash

# MyKart React Web Application Deployment Script

echo "🚀 MyKart React Web Application Deployment"
echo "=========================================="

# Check if we're in the right directory
if [[ ! -f "package.json" ]]; then
    echo "❌ Error: package.json not found!"
    echo "Please run this script from the web-app directory."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js is not installed!"
    echo "Please install Node.js to continue."
    exit 1
fi

echo "📦 Installing server dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to install server dependencies!"
    exit 1
fi

echo "📦 Installing React client dependencies..."
cd client && npm install && cd ..

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to install client dependencies!"
    exit 1
fi

echo "✅ All dependencies installed successfully!"

# Check required services
echo "🔗 Checking required services..."

# Check PostgreSQL
if ! kubectl get pod postgres-wal-0 &> /dev/null; then
    echo "❌ Error: PostgreSQL pod 'postgres-wal-0' not found!"
    echo "Please deploy PostgreSQL first: cd ../postgres && ./deploy-postgres-wal.sh"
    exit 1
fi

# Check Kafka
if ! kubectl get pod kafka-kraft-0 &> /dev/null; then
    echo "❌ Error: Kafka pod 'kafka-kraft-0' not found!"
    echo "Please deploy Kafka first: cd ../../kafka && ./deploy-kafka.sh"
    exit 1
fi

# Check MyKart database
if ! kubectl exec postgres-wal-0 -- psql -U admin -d mykart -c "SELECT 1;" &> /dev/null; then
    echo "❌ Error: MyKart database not found or not accessible!"
    echo "Please initialize the database: cd ../database && ./deploy_database.sh"
    exit 1
fi

echo "✅ All required services are running"

echo "🌐 Starting MyKart React application..."
echo ""
echo "📝 Application will be available at:"
echo "   🖥️  React Frontend: http://localhost:3000"
echo "   � API Backend: http://localhost:3001"
echo ""
echo "💡 Tips:"
echo "   • Make sure PostgreSQL is running: kubectl get pods -l app=postgres-wal"
echo "   • Initialize database: cd ../database && ./deploy_database.sh"
echo "   • The React app will automatically proxy API calls to the backend"
echo "   • Press Ctrl+C to stop both servers"
echo ""

# Get LoadBalancer external IPs dynamically
echo "🔍 Detecting external service IPs..."

# Check if services exist first
if ! kubectl get svc postgres-wal-external &> /dev/null; then
    echo "❌ Error: PostgreSQL external service not found!"
    echo "   Please make sure PostgreSQL is deployed with external service"
    exit 1
fi

if ! kubectl get svc kafka-external &> /dev/null; then
    echo "❌ Error: Kafka external service not found!"
    echo "   Please make sure Kafka is deployed with external service"
    exit 1
fi

POSTGRES_EXTERNAL_IP=$(kubectl get svc postgres-wal-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
KAFKA_EXTERNAL_IP=$(kubectl get svc kafka-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -z "$POSTGRES_EXTERNAL_IP" ] || [ "$POSTGRES_EXTERNAL_IP" = "null" ]; then
    echo "⚠️  Warning: Could not get PostgreSQL external IP, checking for external name..."
    POSTGRES_EXTERNAL_IP=$(kubectl get svc postgres-wal-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -z "$POSTGRES_EXTERNAL_IP" ] || [ "$POSTGRES_EXTERNAL_IP" = "null" ]; then
        echo "❌ Error: PostgreSQL LoadBalancer has no external IP assigned yet"
        echo "   Try: kubectl get svc postgres-wal-external"
        exit 1
    fi
fi

if [ -z "$KAFKA_EXTERNAL_IP" ] || [ "$KAFKA_EXTERNAL_IP" = "null" ]; then
    echo "⚠️  Warning: Could not get Kafka external IP, checking for external name..."
    KAFKA_EXTERNAL_IP=$(kubectl get svc kafka-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -z "$KAFKA_EXTERNAL_IP" ] || [ "$KAFKA_EXTERNAL_IP" = "null" ]; then
        echo "❌ Error: Kafka LoadBalancer has no external IP assigned yet"
        echo "   Try: kubectl get svc kafka-external"
        exit 1
    fi
fi

echo "📡 Service endpoints detected:"
echo "   PostgreSQL: $POSTGRES_EXTERNAL_IP:5432"
echo "   Kafka: $KAFKA_EXTERNAL_IP:9092"

echo "🔗 Testing service connections..."

# Test PostgreSQL connection using kubectl exec to test from inside cluster
echo "🔗 Testing PostgreSQL LoadBalancer connection to $POSTGRES_EXTERNAL_IP:5432..."
if kubectl exec postgres-wal-0 -- pg_isready -h $POSTGRES_EXTERNAL_IP -p 5432 -U admin -d mykart &>/dev/null; then
    echo "✅ PostgreSQL LoadBalancer connection successful!"
else
    echo "⚠️  PostgreSQL LoadBalancer connection test failed, but continuing..."
    echo "   Note: External connectivity will be tested by the application itself"
fi

# Test Kafka connection by checking if topics are accessible
echo "🔗 Testing Kafka cluster accessibility..."
if kubectl exec kafka-kraft-0 -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list &>/dev/null; then
    echo "✅ Kafka cluster is accessible!"
else
    echo "❌ Kafka cluster is not accessible!"
    echo "   Make sure Kafka is running: kubectl get pod kafka-kraft-0"
    exit 1
fi

# Set environment variables
export DB_HOST="$POSTGRES_EXTERNAL_IP"
export DB_PORT="5432"
export DB_NAME="mykart"
export DB_USER="admin"
export DB_PASSWORD="password123"
export KAFKA_BROKERS="$KAFKA_EXTERNAL_IP:9092"
export KAFKAJS_NO_PARTITIONER_WARNING=1

echo "🌐 Environment configured:"
echo "   DB_HOST=$DB_HOST"
echo "   KAFKA_BROKERS=$KAFKA_BROKERS"
echo "   Environment variables set for npm process"

# Cleanup function
cleanup() {
    echo "🧹 Cleaning up..."
    if [ ! -z "$PF_PID" ]; then
        kill $PF_PID 2>/dev/null
    fi
    # Kill any remaining npm processes
    pkill -f "react-scripts start" 2>/dev/null
    pkill -f "node server.js" 2>/dev/null
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

echo "🎯 Starting both React frontend and Node.js backend..."
echo "🔧 Using environment:"
echo "   DB_HOST: $DB_HOST"
echo "   KAFKA_BROKERS: $KAFKA_BROKERS"

# Start both server and client concurrently with environment variables
env DB_HOST="$DB_HOST" DB_PORT="$DB_PORT" DB_NAME="$DB_NAME" DB_USER="$DB_USER" DB_PASSWORD="$DB_PASSWORD" KAFKA_BROKERS="$KAFKA_BROKERS" KAFKAJS_NO_PARTITIONER_WARNING=1 npm start