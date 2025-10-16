#!/bin/bash

# MyKart Complete Deployment Guide

echo "🛒 MyKart E-commerce Application"
echo "=================================="
echo ""

# Check prerequisites
echo "📋 Checking Prerequisites..."

# Check if PostgreSQL is running
if kubectl get pod postgres-0 &> /dev/null; then
    echo "✅ PostgreSQL is running"
else
    echo "❌ PostgreSQL not found. Please deploy PostgreSQL first:"
    echo "   cd ../postgres && ./deploy-postgres.sh"
    echo ""
fi

# Check if Node.js is installed
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js is installed: $NODE_VERSION"
else
    echo "❌ Node.js is not installed"
    echo "   Please install Node.js from https://nodejs.org/"
    echo ""
fi

# Check if npm is installed
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "✅ npm is available: $NPM_VERSION"
else
    echo "❌ npm is not available"
    echo ""
fi

echo ""
echo "🚀 Deployment Steps:"
echo "===================="
echo ""

echo "1️⃣  Deploy & Initialize Database:"
echo "   cd database"
echo "   ./deploy_database.sh"
echo ""

echo "2️⃣  Deploy React Web Application:"
echo "   cd web-app"
echo "   ./deploy_webapp.sh"
echo ""

echo "3️⃣  Access Application:"
echo "   🌐 Frontend: http://localhost:3000"
echo "   🔗 Backend API: http://localhost:3001"
echo "   🗄️  Database: postgres:5432"
echo ""

echo "📊 Features Available:"
echo "====================="
echo "• 1000 sample products across multiple categories"
echo "• Real-time analytics dashboard" 
echo "• Shopping cart with persistent storage"
echo "• Order management system"
echo "• Product impression & click tracking"
echo "• Page hit monitoring"
echo "• Responsive React.js interface"
echo ""

echo "🔧 Manual Deployment:"
echo "====================="
echo "If you prefer manual steps:"
echo ""
echo "Database:"
echo "  cd mykart/database"
echo "  ./deploy_database.sh"
echo ""
echo "Web App:"
echo "  cd mykart/web-app"
echo "  npm install"
echo "  cd client && npm install && cd .."
echo "  npm run dev"
echo ""

echo "📝 Need Help?"
echo "============="
echo "• Check README.md for detailed documentation"
echo "• Verify PostgreSQL: kubectl get pods -l app=postgres"
echo "• Check database: kubectl exec -it postgres-0 -- psql -U admin -d mykart"
echo "• View logs: kubectl logs postgres-0"
echo ""

echo "🎉 Happy Shopping with MyKart!"