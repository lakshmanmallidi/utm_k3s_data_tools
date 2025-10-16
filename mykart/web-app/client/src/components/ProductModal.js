import React from 'react';
import styled from 'styled-components';

const Modal = styled.div`
  display: ${props => props.show ? 'block' : 'none'};
  position: fixed;
  z-index: 1000;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0,0,0,0.5);
`;

const ModalContent = styled.div`
  background-color: white;
  margin: 5% auto;
  padding: 2rem;
  border-radius: 12px;
  width: 90%;
  max-width: 900px;
  max-height: 80vh;
  overflow-y: auto;
`;

const CloseBtn = styled.span`
  color: #aaa;
  float: right;
  font-size: 2rem;
  font-weight: bold;
  cursor: pointer;
  line-height: 1;

  &:hover {
    color: #333;
  }
`;

const ProductContainer = styled.div`
  display: flex;
  gap: 2rem;
  margin: 1rem 0;
  
  @media (max-width: 768px) {
    flex-direction: column;
  }
`;

const ProductImageContainer = styled.div`
  flex: 1;
`;

const ProductImage = styled.div`
  width: 100%;
  height: 300px;
  background-color: #f0f0f0;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.2rem;
  color: #666;
`;

const ProductDetails = styled.div`
  flex: 1;
`;

const ProductTitle = styled.h2`
  margin-bottom: 1rem;
  color: #333;
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

const ProductBrand = styled.span`
  margin-left: 0.5rem;
  color: #666;
`;

const ProductPrice = styled.div`
  font-size: 2rem;
  font-weight: bold;
  color: #667eea;
  margin: 1rem 0;
`;

const ProductDescription = styled.p`
  line-height: 1.6;
  margin: 1rem 0;
  color: #555;
`;

const StockInfo = styled.p`
  color: #666;
  margin: 1rem 0;
  font-weight: 500;
`;

const AddToCartBtn = styled.button`
  width: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 1rem;
  border-radius: 8px;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
  }
`;

const ProductModal = ({ show, product, onClose, onAddToCart }) => {
  if (!product) return null;

  return (
    <Modal show={show} onClick={onClose}>
      <ModalContent onClick={(e) => e.stopPropagation()}>
        <CloseBtn onClick={onClose}>&times;</CloseBtn>
        
        <ProductTitle>{product.name}</ProductTitle>
        
        <ProductContainer>
          <ProductImageContainer>
            <ProductImage>
              📦 {product.name}
            </ProductImage>
          </ProductImageContainer>
          
          <ProductDetails>
            <div>
              <ProductCategory>
                {product.category}
                <ProductBrand> | {product.brand}</ProductBrand>
              </ProductCategory>
            </div>
            
            <ProductPrice>
              ${parseFloat(product.price).toFixed(2)}
            </ProductPrice>
            
            <ProductDescription>
              {product.description}
            </ProductDescription>
            
            <StockInfo>
              <strong>Stock:</strong> {product.stock_quantity} units available
            </StockInfo>
            
            <AddToCartBtn 
              onClick={() => {
                onAddToCart(product.product_id, product.name, product.price);
                onClose();
              }}
            >
              Add to Cart
            </AddToCartBtn>
          </ProductDetails>
        </ProductContainer>
      </ModalContent>
    </Modal>
  );
};

export default ProductModal;