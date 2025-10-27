# 🛒 MyKart E-commerce Application

A full-stack e-commerce application with React frontend, Node.js backend, PostgreSQL database, and Kafka for real-time analytics. Core data (products, orders) stored in PostgreSQL while analytics events (clicks, impressions, cart events, page hits) stream through Kafka topics.

## 🏗️ Architecture

```
MyKart Application
├── 🗄️ Database (PostgreSQL)
│   ├── Products (1000 sample products)
│   ├── Orders & Order Line Items
│   ├── Cart Events Tracking
│   ├── Clicks & Impressions Analytics
│   └── Page Hits Monitoring
├── 🖥️ Backend (Node.js + Express)
│   ├── REST API Endpoints
│   ├── Database Integration
│   └── Analytics Tracking
└── 🌐 Frontend (React.js SPA)
    ├── Component-based Architecture
    ├── Product Catalog with State Management
    ├── Interactive Shopping Cart
    ├── Order Management System
    └── Real-time Analytics Dashboard
```

## 📊 Data Architecture

### PostgreSQL Tables (Core Data)
- **products** - 1000 sample products with details
- **orders** - Order management with timestamps
- **order_line_items** - Individual order items

### Kafka Topics (Analytics Events)
- **mykart-cart-events** - Cart interactions (add/remove/modify)
- **mykart-clicks** - Product click tracking
- **mykart-impressions** - Product view impressions
- **mykart-page-hits** - Page visit analytics

## 🚀 Quick Start

### 1. Deploy Database
```bash
# From the mykart/database directory
cd database
./deploy_database.sh
```

### 2. Start Web Application
```bash
# From the mykart/web-app directory
cd web-app
./deploy_webapp.sh
```

### 3. Access Application
- **Web App**: http://localhost:3000
- **Database**: postgres:5432 (internal) or external IP:5432

## 🎯 Features

### 🛍️ E-commerce Functionality
- ✅ **Product Catalog** - Browse 1000+ products with categories
- ✅ **Product Details** - Detailed product pages with descriptions
- ✅ **Shopping Cart** - Add/remove items with quantity management
- ✅ **Order Processing** - Complete checkout and order placement
- ✅ **Pagination** - Efficient product browsing

### 📈 Analytics & Tracking
- ✅ **Page Hits** - Track every page visit with timestamps
- ✅ **Product Impressions** - Monitor when products are viewed
- ✅ **Click Tracking** - Record product clicks for engagement analysis
- ✅ **Cart Analytics** - Track add/remove/modify cart events
- ✅ **Order Analytics** - Monitor order placement and trends
- ✅ **Real-time Dashboard** - Live analytics display

### 🎨 User Experience
- ✅ **Responsive Design** - Works on all device sizes
- ✅ **Hover Effects** - Automatic impression tracking on hover
- ✅ **Modal Dialogs** - Product details and cart in modals
- ✅ **Real-time Updates** - Live cart count and analytics
- ✅ **Beautiful UI** - Modern gradient design with animations

### ⚛️ React Architecture
- ✅ **Component-based** - Modular, reusable React components
- ✅ **State Management** - React hooks for state and effects
- ✅ **API Integration** - Axios/Fetch for backend communication
- ✅ **Hot Reload** - Development server with live reloading
- ✅ **Production Build** - Optimized build for deployment
- ✅ **Proxy Setup** - Development proxy to backend API

## 🗂️ File Structure

```
mykart/
├── database/
│   ├── init_mykart_db.sql      # Database schema + 1000 products
│   └── deploy_database.sh      # Database deployment script
├── web-app/
│   ├── client/                 # React Frontend
│   │   ├── public/
│   │   │   └── index.html      # React entry point
│   │   ├── src/
│   │   │   ├── components/     # React components
│   │   │   ├── App.js         # Main React App
│   │   │   └── index.js       # React DOM render
│   │   └── package.json       # React dependencies
│   ├── package.json           # Backend dependencies
│   ├── server.js             # Express API server
│   └── deploy_webapp.sh      # Full-stack deployment script
└── README.md                  # This file
```

## 🔌 API Endpoints

### Products
- `GET /api/products` - Get paginated products
- `GET /api/products/:id` - Get single product (tracks click)

### Cart Management
- `POST /api/cart/add` - Add item to cart
- `POST /api/cart/remove` - Remove item from cart
- `GET /api/cart` - Get current cart items

### Orders
- `POST /api/orders` - Place new order

### Analytics
- `POST /api/impressions` - Track product impression
- `GET /api/analytics/summary` - Get analytics overview

## 🎮 User Interactions Tracked

| Action | Database Table | Trigger |
|--------|---------------|---------|
| **Page Visit** | `mykart-page-hits` | Every page load |
| **Product Hover** | `mykart-impressions` | Mouse hover over product |
| **Product Click** | `mykart-clicks` | Click on product card |
| **Add to Cart** | `mykart-cart-events` | Click "Add to Cart" |
| **Remove from Cart** | `mykart-cart-events` | Click "Remove" in cart |
| **Place Order** | `orders` + `order_line_items` | Click "Buy Now" |

## 🔧 Configuration

### Database Connection
```javascript
// Default settings in server.js
const pool = new Pool({
  user: 'admin',
  host: 'postgres',  // or 'localhost' for local development
  database: 'mykart',
  password: 'password123',
  port: 5432,
});
```

### Environment Variables
- `DB_HOST` - Database host (default: postgres)
- `DB_USER` - Database user (default: admin)
- `DB_PASSWORD` - Database password (default: password123)
- `DB_NAME` - Database name (default: mykart)
- `PORT` - Web server port (default: 3000)

## 📊 Sample Analytics Queries

```sql
```bash
# Analytics data is now in Kafka topics
# Use Kafka consumer to read events:

# Monitor cart events
kubectl exec kafka-0 -- /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic mykart-cart-events \
  --from-beginning

# Monitor clicks
kubectl exec kafka-0 -- /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic mykart-clicks \
  --from-beginning
```
```

## 🛠️ Prerequisites

- **Kubernetes Cluster** (K3s recommended)
- **PostgreSQL** (deployed using provided scripts)
- **Node.js** (v14 or higher)
- **npm** (Node Package Manager)

## 🚨 Important Notes

1. **Database First**: Always deploy and initialize the database before starting the web app
2. **Port Forwarding**: The web app script automatically sets up port forwarding to PostgreSQL
3. **Sample Data**: Includes 1000 realistic product entries across multiple categories
4. **Development Mode**: Current setup is for development; production deployment would need additional security
5. **Real-time Tracking**: All user interactions are immediately recorded in the database

## 🎉 Success Verification

After deployment, you should see:
- ✅ 1000 products in the catalog
- ✅ Working pagination (50 pages, 20 products each)
- ✅ Functional shopping cart
- ✅ Order placement capability
- ✅ Live analytics dashboard
- ✅ Database tracking of all interactions

---

**Enjoy shopping with MyKart!** 🛒✨