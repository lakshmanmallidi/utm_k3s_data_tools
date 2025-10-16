import React from 'react';
import styled from 'styled-components';

const HeaderContainer = styled.header`
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 1rem 2rem;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
`;

const Nav = styled.nav`
  display: flex;
  justify-content: space-between;
  align-items: center;
  max-width: 1200px;
  margin: 0 auto;
`;

const Logo = styled.div`
  font-size: 2rem;
  font-weight: bold;
`;

const CartBtn = styled.button`
  background: rgba(255,255,255,0.2);
  border: 2px solid white;
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 25px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 600;

  &:hover {
    background: white;
    color: #667eea;
    transform: translateY(-2px);
  }
`;

const Header = ({ cartCount, onCartClick }) => {
  return (
    <HeaderContainer>
      <Nav>
        <Logo>🛒 MyKart</Logo>
        <CartBtn onClick={onCartClick}>
          Cart ({cartCount})
        </CartBtn>
      </Nav>
    </HeaderContainer>
  );
};

export default Header;