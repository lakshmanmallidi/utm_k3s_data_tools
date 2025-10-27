-- MyKart E-commerce Database Initialization Script
-- Drop existing database and recreate

DROP DATABASE IF EXISTS mykart;
CREATE DATABASE mykart;

-- Connect to the new database
\c mykart;

-- Create Tables

-- 1. Products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    brand VARCHAR(100),
    stock_quantity INTEGER DEFAULT 100,
    image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Orders table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'placed'
);

-- 3. Order line items table
CREATE TABLE order_line_items (
    line_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Note: Analytics tables (cart_events, clicks, impressions, page_hits) 
-- are now handled via Kafka topics instead of PostgreSQL tables

-- Insert 1000 sample products
INSERT INTO products (name, description, price, category, brand, stock_quantity, image_url) VALUES
-- Electronics
('iPhone 15 Pro', 'Latest Apple smartphone with advanced camera system and titanium design. Features A17 Pro chip, ProRAW photography, and all-day battery life.', 999.00, 'Electronics', 'Apple', 50, 'https://via.placeholder.com/300x300/007acc/ffffff?text=iPhone+15'),
('Samsung Galaxy S24', 'Premium Android smartphone with AI features and exceptional display quality. Includes S Pen support and professional photography capabilities.', 849.00, 'Electronics', 'Samsung', 75, 'https://via.placeholder.com/300x300/1f4e79/ffffff?text=Galaxy+S24'),
('MacBook Air M3', 'Ultra-thin laptop powered by Apple M3 chip for exceptional performance and battery life. Perfect for students and professionals.', 1299.00, 'Electronics', 'Apple', 30, 'https://via.placeholder.com/300x300/007acc/ffffff?text=MacBook+Air'),
('Dell XPS 13', 'Premium ultrabook with InfinityEdge display and powerful Intel processors. Ideal for business and creative work.', 1099.00, 'Electronics', 'Dell', 25, 'https://via.placeholder.com/300x300/0066cc/ffffff?text=Dell+XPS'),
('Sony WH-1000XM5', 'Industry-leading noise canceling wireless headphones with exceptional sound quality and all-day comfort.', 349.00, 'Electronics', 'Sony', 100, 'https://via.placeholder.com/300x300/000000/ffffff?text=Sony+WH1000XM5'),

-- Clothing
('Nike Air Max 90', 'Classic running shoes with iconic design and superior comfort. Features Air cushioning and durable construction.', 120.00, 'Clothing', 'Nike', 200, 'https://via.placeholder.com/300x300/ff6b35/ffffff?text=Nike+Air+Max'),
('Adidas Ultraboost 22', 'High-performance running shoes with responsive Boost midsole and Primeknit upper for ultimate comfort.', 180.00, 'Clothing', 'Adidas', 150, 'https://via.placeholder.com/300x300/000000/ffffff?text=Ultraboost'),
('Levis 501 Jeans', 'Original straight fit jeans with classic styling and premium denim construction. A timeless wardrobe essential.', 89.00, 'Clothing', 'Levis', 300, 'https://via.placeholder.com/300x300/4169e1/ffffff?text=Levis+501'),
('Champion Hoodie', 'Comfortable pullover hoodie made from soft cotton blend. Perfect for casual wear and layering.', 45.00, 'Clothing', 'Champion', 250, 'https://via.placeholder.com/300x300/ff1744/ffffff?text=Champion'),
('Ray-Ban Aviator', 'Classic aviator sunglasses with premium lenses and iconic metal frame. Offers 100% UV protection.', 165.00, 'Clothing', 'Ray-Ban', 120, 'https://via.placeholder.com/300x300/ffd700/000000?text=Ray-Ban'),

-- Home & Garden
('Dyson V15 Detect', 'Advanced cordless vacuum with laser dust detection and powerful suction. Features multiple attachments for versatile cleaning.', 649.00, 'Home', 'Dyson', 40, 'https://via.placeholder.com/300x300/6a1b9a/ffffff?text=Dyson+V15'),
('Instant Pot Duo', '7-in-1 multi-cooker that pressure cooks, slow cooks, sautés, and more. Perfect for quick and healthy meals.', 89.00, 'Home', 'Instant Pot', 80, 'https://via.placeholder.com/300x300/e65100/ffffff?text=Instant+Pot'),
('Philips Hue Starter Kit', 'Smart LED lighting system with millions of colors and wireless control. Create the perfect ambiance for any occasion.', 199.00, 'Home', 'Philips', 60, 'https://via.placeholder.com/300x300/0097a7/ffffff?text=Philips+Hue'),
('KitchenAid Stand Mixer', 'Professional-grade stand mixer with powerful motor and multiple attachments. Essential for baking enthusiasts.', 379.00, 'Home', 'KitchenAid', 35, 'https://via.placeholder.com/300x300/d32f2f/ffffff?text=KitchenAid'),
('Nespresso Vertuo', 'Premium coffee machine that brews authentic espresso and coffee with rich crema using innovative centrifusion technology.', 179.00, 'Home', 'Nespresso', 70, 'https://via.placeholder.com/300x300/5d4037/ffffff?text=Nespresso'),

-- Books
('The Psychology of Money', 'Insightful book about the intersection of psychology and personal finance. Learn timeless lessons about wealth and happiness.', 16.99, 'Books', 'Harriman House', 500, 'https://via.placeholder.com/300x400/2e7d32/ffffff?text=Psychology+Money'),
('Atomic Habits', 'Practical guide to building good habits and breaking bad ones. Discover proven strategies for remarkable results.', 18.99, 'Books', 'Avery', 400, 'https://via.placeholder.com/300x400/1976d2/ffffff?text=Atomic+Habits'),
('The Silent Patient', 'Gripping psychological thriller about a woman who refuses to speak after allegedly murdering her husband.', 14.99, 'Books', 'Celadon Books', 300, 'https://via.placeholder.com/300x400/7b1fa2/ffffff?text=Silent+Patient'),
('Educated', 'Powerful memoir about education, family, and the struggle for self-invention. A story of fierce determination.', 17.99, 'Books', 'Random House', 250, 'https://via.placeholder.com/300x400/f57c00/ffffff?text=Educated'),
('Becoming', 'Intimate memoir by former First Lady Michelle Obama. An inspiring story of hope, change, and personal growth.', 19.99, 'Books', 'Crown', 350, 'https://via.placeholder.com/300x400/c2185b/ffffff?text=Becoming'),

-- Sports
('Wilson Tennis Racket', 'Professional-grade tennis racket with carbon fiber construction and precision engineering for enhanced performance.', 149.00, 'Sports', 'Wilson', 80, 'https://via.placeholder.com/300x300/ff5722/ffffff?text=Wilson+Tennis'),
('Spalding Basketball', 'Official size basketball with superior grip and bounce. Perfect for indoor and outdoor play.', 29.99, 'Sports', 'Spalding', 200, 'https://via.placeholder.com/300x300/ff9800/000000?text=Basketball'),
('Yoga Mat Premium', 'High-quality yoga mat with superior grip and cushioning. Made from eco-friendly materials for sustainable practice.', 39.99, 'Sports', 'Manduka', 150, 'https://via.placeholder.com/300x300/4caf50/ffffff?text=Yoga+Mat'),
('Dumbbells Set', 'Adjustable dumbbell set with comfortable grip and quick weight changes. Perfect for home fitness routines.', 299.00, 'Sports', 'Bowflex', 50, 'https://via.placeholder.com/300x300/607d8b/ffffff?text=Dumbbells'),
('Fitness Tracker', 'Advanced fitness tracker with heart rate monitoring, GPS, and sleep tracking. Motivate your active lifestyle.', 199.00, 'Sports', 'Fitbit', 120, 'https://via.placeholder.com/300x300/3f51b5/ffffff?text=Fitbit');

-- Generate more products to reach 1000 total
-- Electronics category (additional products)
DO $$
DECLARE
    i INTEGER;
    categories TEXT[] := ARRAY['Electronics', 'Clothing', 'Home', 'Books', 'Sports'];
    brands TEXT[] := ARRAY['Apple', 'Samsung', 'Sony', 'LG', 'HP', 'Canon', 'Nike', 'Adidas', 'Puma', 'Under Armour'];
    product_names TEXT[] := ARRAY[
        'Wireless Headphones', 'Bluetooth Speaker', 'Smart Watch', 'Tablet', 'Gaming Mouse',
        'Keyboard', 'Monitor', 'Camera', 'Printer', 'Router', 'Hard Drive', 'Power Bank',
        'T-Shirt', 'Jeans', 'Sneakers', 'Jacket', 'Shirt', 'Shorts', 'Dress', 'Sweater',
        'Coffee Maker', 'Blender', 'Toaster', 'Air Fryer', 'Microwave', 'Vacuum Cleaner',
        'Novel', 'Cookbook', 'Biography', 'Textbook', 'Magazine', 'Comic Book',
        'Football', 'Soccer Ball', 'Golf Clubs', 'Running Shoes', 'Gym Bag', 'Water Bottle'
    ];
BEGIN
    FOR i IN 26..1000 LOOP
        INSERT INTO products (name, description, price, category, brand, stock_quantity, image_url) VALUES (
            product_names[1 + (i % array_length(product_names, 1))] || ' ' || i,
            'High-quality product with excellent features and reliable performance. Perfect for everyday use and special occasions. Designed with user comfort and durability in mind. Offers great value for money and comes with warranty coverage. Suitable for all ages and skill levels.',
            ROUND((RANDOM() * 800 + 20)::numeric, 2),
            categories[1 + (i % array_length(categories, 1))],
            brands[1 + (i % array_length(brands, 1))],
            FLOOR(RANDOM() * 200 + 10)::integer,
            'https://via.placeholder.com/300x300/' || 
            CASE (i % 6)
                WHEN 0 THEN 'ff6b35'
                WHEN 1 THEN '007acc'
                WHEN 2 THEN '2e7d32'
                WHEN 3 THEN '7b1fa2'
                WHEN 4 THEN 'f57c00'
                ELSE 'c2185b'
            END || '/ffffff?text=Product+' || i
        );
    END LOOP;
END $$;

-- Insert some sample orders and order line items
INSERT INTO orders (total_amount, status) VALUES
(156.98, 'completed'),
(89.99, 'completed'),
(299.99, 'shipped'),
(45.50, 'processing'),
(189.99, 'completed');

INSERT INTO order_line_items (order_id, product_id, quantity, price) VALUES
(1, 1, 1, 999.00),
(1, 6, 2, 120.00),
(2, 8, 1, 89.00),
(3, 11, 1, 649.00),
(4, 9, 1, 45.00),
(5, 5, 1, 349.00);

-- Create indexes for better performance
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_price ON products(price);

-- Analytics views removed - data now flows through Kafka topics

-- Database initialization complete
SELECT 'MyKart database initialized successfully with ' || COUNT(*) || ' products!' AS initialization_status FROM products;