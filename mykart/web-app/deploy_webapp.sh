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
if ! kubectl get pod postgres-0 &> /dev/null; then
    echo "⚠️  Warning: PostgreSQL pod 'postgres-0' not found!"
    echo "Make sure PostgreSQL is deployed and the MyKart database is initialized."
    echo "You can still run the web app, but it won't connect to the database."
fi

echo "🌐 Starting MyKart React application..."
echo ""
echo "📝 Application will be available at:"
echo "   🖥️  React Frontend: http://localhost:3000"
echo "   � API Backend: http://localhost:3001"
echo ""
echo "💡 Tips:"
echo "   • Make sure PostgreSQL is running: kubectl get pods -l app=postgres"
echo "   • Initialize database: cd ../database && ./deploy_database.sh"
echo "   • The React app will automatically proxy API calls to the backend"
echo "   • Press Ctrl+C to stop both servers"
echo ""

# Set environment variables for database connection
export DB_HOST="localhost"  # Change to 'postgres' if running in Kubernetes
export DB_PORT="5432"
export DB_NAME="mykart"
export DB_USER="admin"
export DB_PASSWORD="password123"

# If running in Kubernetes environment, use port-forward to connect to PostgreSQL
if kubectl get pod postgres-0 &> /dev/null; then
    echo "🔀 Setting up port forwarding to PostgreSQL..."
    kubectl port-forward svc/postgres 5432:5432 &
    PF_PID=$!
    
    # Wait a moment for port forwarding to establish
    sleep 3
    
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
fi

echo "🎯 Starting both React frontend and Node.js backend..."

# Start both server and client concurrently
npm start