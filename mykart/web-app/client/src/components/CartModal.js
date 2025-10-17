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
  max-width: 800px;
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

const CartTitle = styled.h2`
  margin-bottom: 1.5rem;
  color: #333;
`;

const CartItem = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #eee;
`;

const ItemInfo = styled.div`
  flex: 1;
`;

const ItemName = styled.div`
  font-weight: 600;
  margin-bottom: 0.5rem;
`;

const ItemDetails = styled.div`
  color: #666;
  font-size: 0.9rem;
`;

const RemoveBtn = styled.button`
  background: #ff4444;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  transition: background 0.3s ease;

  &:hover {
    background: #cc0000;
  }
`;

const CartTotal = styled.div`
  font-size: 1.5rem;
  font-weight: bold;
  text-align: right;
  margin: 1rem 0;
  color: #667eea;
`;

const BuyBtn = styled.button`
  width: 100%;
  background: linear-gradient(135deg, #4caf50 0%, #45a049 100%);
  color: white;
  border: none;
  padding: 1rem;
  border-radius: 8px;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  margin-top: 1rem;
  transition: all 0.3s ease;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(76, 175, 80, 0.4);
  }
`;

const EmptyCart = styled.div`
  text-align: center;
  padding: 2rem;
  color: #666;
  font-size: 1.1rem;
`;

const CartModal = ({ show, cartItems, onClose, onRemoveItem, onPlaceOrder }) => {
  const total = cartItems.reduce((sum, item) => sum + (parseFloat(item.price) * item.quantity), 0);

  return (
    <Modal show={show} onClick={onClose}>
      <ModalContent onClick={(e) => e.stopPropagation()}>
        <CloseBtn onClick={onClose}>&times;</CloseBtn>
        <CartTitle>Shopping Cart</CartTitle>
        
        {cartItems.length === 0 ? (
          <EmptyCart>Your cart is empty</EmptyCart>
        ) : (
          <>
            {cartItems.map(item => (
              <CartItem key={item.product_id}>
                <ItemInfo>
                  <ItemName>{item.name}</ItemName>
                  <ItemDetails>
                    ${parseFloat(item.price).toFixed(2)} × {item.quantity} = ${(parseFloat(item.price) * item.quantity).toFixed(2)}
                  </ItemDetails>
                </ItemInfo>
                <RemoveBtn onClick={() => onRemoveItem(item.product_id)}>
                  Remove
                </RemoveBtn>
              </CartItem>
            ))}
            
            <CartTotal>Total: ${total.toFixed(2)}</CartTotal>
            
            <BuyBtn onClick={onPlaceOrder}>
              Buy Now
            </BuyBtn>
          </>
        )}
      </ModalContent>
    </Modal>
  );
};

export default CartModal;