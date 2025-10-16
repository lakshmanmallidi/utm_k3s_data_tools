import React from 'react';
import styled from 'styled-components';

const GridContainer = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
`;

const ProductCard = styled.div`
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
  transition: all 0.3s ease;
  cursor: pointer;

  &:hover {
    transform: translateY(-5px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.15);
  }
`;

const ProductImage = styled.div`
  width: 100%;
  height: 200px;
  background-color: #f0f0f0;
  border-radius: 8px;
  margin-bottom: 1rem;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.9rem;
  color: #666;
`;

const ProductName = styled.div`
  font-size: 1.1rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
  color: #333;
`;

const ProductPrice = styled.div`
  font-size: 1.3rem;
  font-weight: bold;
  color: #667eea;
  margin-bottom: 0.5rem;
`;

const ProductCategory = styled.div`
  display: inline-block;
  background: #e3f2fd;
  color: #1976d2;
  padding: 0.3rem 0.8rem;
  border-radius: 15px;
  font-size: 0.8rem;
  margin-bottom: 1rem;
`;

const AddToCartBtn = styled.button`
  width: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 0.8rem;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s ease;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
  }
`;

const ProductGrid = ({ products, onProductHover, onProductClick, onAddToCart }) => {
  return (
    <GridContainer>
      {products.map(product => (
        <ProductCard
          key={product.product_id}
          onMouseEnter={() => onProductHover(product.product_id)}
          onClick={() => onProductClick(product.product_id)}
        >
          <ProductImage>
            📦 {product.name}
          </ProductImage>
          <ProductName>{product.name}</ProductName>
          <ProductCategory>{product.category}</ProductCategory>
          <ProductPrice>${parseFloat(product.price).toFixed(2)}</ProductPrice>
          <AddToCartBtn
            onClick={(e) => {
              e.stopPropagation();
              onAddToCart(product.product_id, product.name, product.price);
            }}
          >
            Add to Cart
          </AddToCartBtn>
        </ProductCard>
      ))}
    </GridContainer>
  );
};

export default ProductGrid;