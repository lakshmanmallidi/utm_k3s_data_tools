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

# Check PostgreSQL connection
echo "🔗 Checking database connection..."
if ! kubectl get pod postgres-wal-0 &> /dev/null; then
    echo "⚠️  Warning: PostgreSQL pod 'postgres-wal-0' not found!"
    echo "Make sure PostgreSQL WAL is deployed and the MyKart database is initialized."
    echo "You can still run the web app, but it won't connect to the database."
fi

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

# Get LoadBalancer external IP dynamically
POSTGRES_EXTERNAL_IP=$(kubectl get svc postgres-wal-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -z "$POSTGRES_EXTERNAL_IP" ]; then
    echo "⚠️  Warning: Could not get PostgreSQL external IP, using default..."
    POSTGRES_EXTERNAL_IP="192.168.0.25"
fi

echo "🔗 Testing PostgreSQL LoadBalancer connection to $POSTGRES_EXTERNAL_IP:5432..."

# Test direct LoadBalancer connection
if nc -zv $POSTGRES_EXTERNAL_IP 5432 2>/dev/null; then
    echo "✅ Direct LoadBalancer connection successful!"
    export DB_HOST="$POSTGRES_EXTERNAL_IP"
    export DB_PORT="5432"
else
    echo "❌ LoadBalancer connection failed!"
    exit 1
fi

export DB_NAME="mykart"
export DB_USER="admin"
export DB_PASSWORD="password123"

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

# Start both server and client concurrently
npm start