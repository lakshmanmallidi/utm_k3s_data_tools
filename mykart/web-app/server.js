const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const { Kafka } = require('kafkajs');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Serve React build files in production
if (process.env.NODE_ENV === 'production') {
  app.use(express.static(path.join(__dirname, 'client/build')));
}

// PostgreSQL connection
const pool = new Pool({
  user: process.env.DB_USER || 'admin',
  host: process.env.DB_HOST || '192.168.0.25',  // Use external LoadBalancer IP
  database: process.env.DB_NAME || 'mykart',
  password: process.env.DB_PASSWORD || 'password123',
  port: process.env.DB_PORT || 5432,
});

// Kafka connection
const kafkaBrokers = process.env.KAFKA_BROKERS || '192.168.0.25:9092';
console.log('🔧 Kafka brokers configuration:', kafkaBrokers);

const kafka = new Kafka({
  clientId: 'mykart-webapp',
  brokers: [kafkaBrokers],  // Use external LoadBalancer IP
  connectionTimeout: 3000,
  requestTimeout: 25000,
  retry: {
    initialRetryTime: 100,
    retries: 8
  }
});

const producer = kafka.producer();

// Initialize Kafka producer
const initKafka = async () => {
  try {
    await producer.connect();
    console.log('✅ Connected to Kafka');
  } catch (error) {
    console.error('❌ Error connecting to Kafka:', error);
  }
};

initKafka();

// Test database connection
pool.connect((err, client, release) => {
  if (err) {
    console.error('Error connecting to database:', err.stack);
  } else {
    console.log('✅ Connected to MyKart database');
    release();
  }
});

// API Routes

// Get all products with pagination
app.get('/api/products', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    
    // Track page hit via Kafka
    await producer.send({
      topic: 'mykart.page-hits',
      messages: [{
        key: 'page-hit',
        value: JSON.stringify({
          page_name: 'products',
          hit_timestamp: new Date().toISOString(),
          user_agent: req.headers['user-agent'],
          ip: req.ip
        })
      }]
    });
    
    const result = await pool.query(
      'SELECT * FROM products ORDER BY product_id LIMIT $1 OFFSET $2',
      [limit, offset]
    );
    
    const countResult = await pool.query('SELECT COUNT(*) FROM products');
    const totalProducts = parseInt(countResult.rows[0].count);
    
    res.json({
      products: result.rows,
      pagination: {
        page,
        limit,
        total: totalProducts,
        totalPages: Math.ceil(totalProducts / limit)
      }
    });
  } catch (err) {
    console.error('Error fetching products:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get single product
app.get('/api/products/:id', async (req, res) => {
  try {
    const productId = req.params.id;
    
    // Track click via Kafka
    await producer.send({
      topic: 'mykart.clicks',
      messages: [{
        key: `product-${productId}`,
        value: JSON.stringify({
          product_id: parseInt(productId),
          click_timestamp: new Date().toISOString(),
          user_agent: req.headers['user-agent'],
          ip: req.ip
        })
      }]
    });
    
    const result = await pool.query('SELECT * FROM products WHERE product_id = $1', [productId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error fetching product:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Track impression
app.post('/api/impressions', async (req, res) => {
  try {
    const { productId } = req.body;
    
    // Track impression via Kafka
    await producer.send({
      topic: 'mykart.impressions',
      messages: [{
        key: `product-${productId}`,
        value: JSON.stringify({
          product_id: parseInt(productId),
          impression_timestamp: new Date().toISOString(),
          user_agent: req.headers['user-agent'],
          ip: req.ip
        })
      }]
    });
    
    res.json({ success: true });
  } catch (err) {
    console.error('Error tracking impression:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Add to cart
app.post('/api/cart/add', async (req, res) => {
  try {
    const { productId, quantity } = req.body;
    
    // Track cart event via Kafka
    await producer.send({
      topic: 'mykart.cart-events',
      messages: [{
        key: `product-${productId}`,
        value: JSON.stringify({
          product_id: parseInt(productId),
          quantity: quantity || 1,
          event_type: 'added',
          event_timestamp: new Date().toISOString(),
          user_agent: req.headers['user-agent'],
          ip: req.ip
        })
      }]
    });
    
    res.json({ success: true, message: 'Product added to cart' });
  } catch (err) {
    console.error('Error adding to cart:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Remove from cart
app.post('/api/cart/remove', async (req, res) => {
  try {
    const { productId, quantity } = req.body;
    
    // Track cart event via Kafka
    await producer.send({
      topic: 'mykart.cart-events',
      messages: [{
        key: `product-${productId}`,
        value: JSON.stringify({
          product_id: parseInt(productId),
          quantity: quantity || 1,
          event_type: 'removed',
          event_timestamp: new Date().toISOString(),
          user_agent: req.headers['user-agent'],
          ip: req.ip
        })
      }]
    });
    
    res.json({ success: true, message: 'Product removed from cart' });
  } catch (err) {
    console.error('Error removing from cart:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get cart items
app.get('/api/cart', async (req, res) => {
  try {
    // Track page hit via Kafka
    await producer.send({
      topic: 'mykart.page-hits',
      messages: [{
        key: 'page-hit',
        value: JSON.stringify({
          page_name: 'cart',
          hit_timestamp: new Date().toISOString(),
          user_agent: req.headers['user-agent'],
          ip: req.ip
        })
      }]
    });
    
    // Return empty cart for now - cart state would need to be managed differently
    // without database persistence (e.g., session storage, Redis, etc.)
    res.json({ cartItems: [] });
  } catch (err) {
    console.error('Error fetching cart:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Place order
app.post('/api/orders', async (req, res) => {
  try {
    const { cartItems } = req.body;
    
    if (!cartItems || cartItems.length === 0) {
      return res.status(400).json({ error: 'Cart is empty' });
    }
    
    // Calculate total
    const total = cartItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    // Create order
    const orderResult = await pool.query(
      'INSERT INTO orders (total_amount, status) VALUES ($1, $2) RETURNING order_id',
      [total, 'placed']
    );
    
    const orderId = orderResult.rows[0].order_id;
    
    // Create order line items
    for (const item of cartItems) {
      await pool.query(
        'INSERT INTO order_line_items (order_id, product_id, quantity, price) VALUES ($1, $2, $3, $4)',
        [orderId, item.product_id, item.quantity, item.price]
      );
    }
    
    res.json({ 
      success: true, 
      orderId, 
      message: 'Order placed successfully!',
      total: total.toFixed(2)
    });
  } catch (err) {
    console.error('Error placing order:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Analytics endpoints (simplified - clicks/impressions now in Kafka)
app.get('/api/analytics/summary', async (req, res) => {
  try {
    const [productsCount, ordersCount] = await Promise.all([
      pool.query('SELECT COUNT(*) FROM products'),
      pool.query('SELECT COUNT(*) FROM orders')
    ]);
    
    res.json({
      totalProducts: parseInt(productsCount.rows[0].count),
      totalOrders: parseInt(ordersCount.rows[0].count),
      totalClicks: 0, // Placeholder - will implement Kafka-based analytics later
      totalImpressions: 0 // Placeholder - will implement Kafka-based analytics later
    });
  } catch (err) {
    console.error('Error fetching analytics:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Catch-all handler for React routes (production only)
if (process.env.NODE_ENV === 'production') {
  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'client/build', 'index.html'));
  });
}

// Graceful shutdown
const gracefulShutdown = async () => {
  console.log('🛑 Shutting down gracefully...');
  try {
    await producer.disconnect();
    console.log('✅ Kafka producer disconnected');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during shutdown:', error);
    process.exit(1);
  }
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 MyKart server running on port ${PORT}`);
  console.log(`📱 Access the app at: http://localhost:${PORT}`);
  console.log(`📡 Analytics events publishing to Kafka topics:`);
  console.log(`   - mykart.cart-events`);
  console.log(`   - mykart.clicks`);
  console.log(`   - mykart.impressions`);
  console.log(`   - mykart.page-hits`);
});