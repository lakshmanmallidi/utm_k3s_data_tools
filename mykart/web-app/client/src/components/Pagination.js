import React from 'react';
import styled from 'styled-components';

const PaginationContainer = styled.div`
  display: flex;
  justify-content: center;
  gap: 0.5rem;
  margin: 2rem 0;
`;

const PageBtn = styled.button`
  padding: 0.5rem 1rem;
  border: 2px solid #667eea;
  background: ${props => props.active ? '#667eea' : 'white'};
  color: ${props => props.active ? 'white' : '#667eea'};
  border-radius: 5px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 600;

  &:hover {
    background: #667eea;
    color: white;
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
`;

const PageInfo = styled.div`
  display: flex;
  align-items: center;
  margin: 0 1rem;
  color: #666;
  font-size: 0.9rem;
`;

const Pagination = ({ pagination, currentPage, onPageChange }) => {
  if (!pagination.totalPages || pagination.totalPages <= 1) {
    return null;
  }

  const generatePageNumbers = () => {
    const pages = [];
    const maxVisible = 10;
    const total = pagination.totalPages;
    
    let start = Math.max(1, currentPage - Math.floor(maxVisible / 2));
    let end = Math.min(total, start + maxVisible - 1);
    
    if (end - start + 1 < maxVisible) {
      start = Math.max(1, end - maxVisible + 1);
    }

    for (let i = start; i <= end; i++) {
      pages.push(i);
    }
    
    return pages;
  };

  return (
    <PaginationContainer>
      <PageBtn
        disabled={currentPage === 1}
        onClick={() => onPageChange(1)}
      >
        First
      </PageBtn>
      
      <PageBtn
        disabled={currentPage === 1}
        onClick={() => onPageChange(currentPage - 1)}
      >
        Previous
      </PageBtn>

      {generatePageNumbers().map(page => (
        <PageBtn
          key={page}
          active={page === currentPage}
          onClick={() => onPageChange(page)}
        >
          {page}
        </PageBtn>
      ))}

      <PageBtn
        disabled={currentPage === pagination.totalPages}
        onClick={() => onPageChange(currentPage + 1)}
      >
        Next
      </PageBtn>
      
      <PageBtn
        disabled={currentPage === pagination.totalPages}
        onClick={() => onPageChange(pagination.totalPages)}
      >
        Last
      </PageBtn>

      <PageInfo>
        Page {currentPage} of {pagination.totalPages} 
        ({pagination.total.toLocaleString()} products)
      </PageInfo>
    </PaginationContainer>
  );
};

export default Pagination;