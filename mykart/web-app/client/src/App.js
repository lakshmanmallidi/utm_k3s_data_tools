import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import axios from 'axios';
import Header from './components/Header';
import ProductGrid from './components/ProductGrid';
import Analytics from './components/Analytics';
import CartModal from './components/CartModal';
import ProductModal from './components/ProductModal';
import Pagination from './components/Pagination';

const Container = styled.div`
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
`;

const SectionTitle = styled.h1`
  font-size: 2rem;
  margin-bottom: 1.5rem;
  text-align: center;
  color: #333;
`;

const Loading = styled.div`
  text-align: center;
  padding: 2rem;
  font-size: 1.1rem;
  color: #666;
`;

function App() {
  const [products, setProducts] = useState([]);
  const [cartItems, setCartItems] = useState([]);
  const [analytics, setAnalytics] = useState({});
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [pagination, setPagination] = useState({});
  const [showCart, setShowCart] = useState(false);
  const [showProduct, setShowProduct] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState(null);

  // Load initial data
  useEffect(() => {
    loadProducts();
    loadCart();
    loadAnalytics();
  }, []);

  // Load products
  const loadProducts = async (page = 1) => {
    try {
      setLoading(true);
      const response = await axios.get(`/api/products?page=${page}&limit=20`);
      setProducts(response.data.products);
      setPagination(response.data.pagination);
      setCurrentPage(page);
    } catch (error) {
      console.error('Error loading products:', error);
    } finally {
      setLoading(false);
    }
  };

  // Load cart
  const loadCart = async () => {
    try {
      const response = await axios.get('/api/cart');
      setCartItems(response.data.cartItems || []);
    } catch (error) {
      console.error('Error loading cart:', error);
    }
  };

  // Load analytics
  const loadAnalytics = async () => {
    try {
      const response = await axios.get('/api/analytics/summary');
      setAnalytics(response.data);
    } catch (error) {
      console.error('Error loading analytics:', error);
    }
  };

  // Track impression
  const trackImpression = async (productId) => {
    try {
      await axios.post('/api/impressions', { productId });
      // Refresh analytics after tracking
      loadAnalytics();
    } catch (error) {
      console.error('Error tracking impression:', error);
    }
  };

  // Show product detail
  const showProductDetail = async (productId) => {
    try {
      const response = await axios.get(`/api/products/${productId}`);
      setSelectedProduct(response.data);
      setShowProduct(true);
      // Refresh analytics after click
      loadAnalytics();
    } catch (error) {
      console.error('Error loading product detail:', error);
    }
  };

  // Add to cart
  const addToCart = async (productId, name, price) => {
    try {
      await axios.post('/api/cart/add', { productId, quantity: 1 });
      
      // Update local cart state
      const existingItem = cartItems.find(item => item.product_id === productId);
      if (existingItem) {
        setCartItems(cartItems.map(item => 
          item.product_id === productId 
            ? { ...item, quantity: item.quantity + 1 }
            : item
        ));
      } else {
        setCartItems([...cartItems, {
          product_id: productId,
          name: name,
          price: parseFloat(price),
          quantity: 1
        }]);
      }
      
      alert(`${name} added to cart!`);
    } catch (error) {
      console.error('Error adding to cart:', error);
    }
  };

  // Remove from cart
  const removeFromCart = async (productId) => {
    try {
      await axios.post('/api/cart/remove', { productId, quantity: 1 });
      setCartItems(cartItems.filter(item => item.product_id !== productId));
    } catch (error) {
      console.error('Error removing from cart:', error);
    }
  };

  // Place order
  const placeOrder = async () => {
    if (cartItems.length === 0) {
      alert('Your cart is empty!');
      return;
    }

    try {
      const response = await axios.post('/api/orders', { cartItems });
      const data = response.data;

      if (response.status === 200) {
        alert(`Order placed successfully! Order ID: ${data.orderId}\nTotal: $${data.total}`);
        setCartItems([]);
        setShowCart(false);
        loadAnalytics(); // Refresh analytics
      }
    } catch (error) {
      console.error('Error placing order:', error);
      alert('Error placing order. Please try again.');
    }
  };

  // Calculate cart count
  const cartCount = cartItems.reduce((total, item) => total + item.quantity, 0);

  return (
    <div className="App">
      <Header 
        cartCount={cartCount}
        onCartClick={() => setShowCart(true)}
      />
      
      <Container>
        <Analytics analytics={analytics} />
        
        <SectionTitle>Featured Products</SectionTitle>
        
        {loading ? (
          <Loading>Loading products...</Loading>
        ) : (
          <>
            <ProductGrid 
              products={products}
              onProductHover={trackImpression}
              onProductClick={showProductDetail}
              onAddToCart={addToCart}
            />
            
            <Pagination 
              pagination={pagination}
              currentPage={currentPage}
              onPageChange={loadProducts}
            />
          </>
        )}
      </Container>

      <CartModal 
        show={showCart}
        cartItems={cartItems}
        onClose={() => setShowCart(false)}
        onRemoveItem={removeFromCart}
        onPlaceOrder={placeOrder}
      />

      <ProductModal 
        show={showProduct}
        product={selectedProduct}
        onClose={() => setShowProduct(false)}
        onAddToCart={addToCart}
      />
    </div>
  );
}

export default App;