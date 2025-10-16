const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');

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
  host: process.env.DB_HOST || 'localhost',  // Changed from 'postgres' to 'localhost' for local dev
  database: process.env.DB_NAME || 'mykart',
  password: process.env.DB_PASSWORD || 'password123',
  port: process.env.DB_PORT || 5432,
});

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
    
    // Track page hit
    await pool.query('INSERT INTO page_hits (page_name) VALUES ($1)', ['products']);
    
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
    
    // Track click
    await pool.query('INSERT INTO clicks (product_id) VALUES ($1)', [productId]);
    
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
    await pool.query('INSERT INTO impressions (product_id) VALUES ($1)', [productId]);
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
    await pool.query(
      'INSERT INTO cart_events (product_id, quantity, event_type) VALUES ($1, $2, $3)',
      [productId, quantity || 1, 'added']
    );
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
    await pool.query(
      'INSERT INTO cart_events (product_id, quantity, event_type) VALUES ($1, $2, $3)',
      [productId, quantity || 1, 'removed']
    );
    res.json({ success: true, message: 'Product removed from cart' });
  } catch (err) {
    console.error('Error removing from cart:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get cart items
app.get('/api/cart', async (req, res) => {
  try {
    // Track page hit
    await pool.query('INSERT INTO page_hits (page_name) VALUES ($1)', ['cart']);
    
    // Get current cart state (simplified - in real app you'd need user sessions)
    const result = await pool.query(`
      SELECT 
        p.product_id,
        p.name,
        p.price,
        p.image_url,
        SUM(CASE 
          WHEN ce.event_type = 'added' THEN ce.quantity
          WHEN ce.event_type = 'increased' THEN ce.quantity  
          WHEN ce.event_type = 'removed' THEN -ce.quantity
          WHEN ce.event_type = 'decreased' THEN -ce.quantity
          ELSE 0 
        END) as quantity
      FROM cart_events ce
      JOIN products p ON ce.product_id = p.product_id
      GROUP BY p.product_id, p.name, p.price, p.image_url
      HAVING SUM(CASE 
        WHEN ce.event_type = 'added' THEN ce.quantity
        WHEN ce.event_type = 'increased' THEN ce.quantity  
        WHEN ce.event_type = 'removed' THEN -ce.quantity
        WHEN ce.event_type = 'decreased' THEN -ce.quantity
        ELSE 0 
      END) > 0
    `);
    
    res.json({ cartItems: result.rows });
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

// Analytics endpoints
app.get('/api/analytics/summary', async (req, res) => {
  try {
    const [productsCount, ordersCount, clicksCount, impressionsCount] = await Promise.all([
      pool.query('SELECT COUNT(*) FROM products'),
      pool.query('SELECT COUNT(*) FROM orders'),
      pool.query('SELECT COUNT(*) FROM clicks'),
      pool.query('SELECT COUNT(*) FROM impressions')
    ]);
    
    res.json({
      totalProducts: parseInt(productsCount.rows[0].count),
      totalOrders: parseInt(ordersCount.rows[0].count), 
      totalClicks: parseInt(clicksCount.rows[0].count),
      totalImpressions: parseInt(impressionsCount.rows[0].count)
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

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 MyKart server running on port ${PORT}`);
  console.log(`📱 Access the app at: http://localhost:${PORT}`);
});