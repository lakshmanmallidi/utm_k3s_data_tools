import React from 'react';
import styled from 'styled-components';

const AnalyticsContainer = styled.div`
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
  margin-bottom: 2rem;
`;

const SectionTitle = styled.h2`
  font-size: 2rem;
  margin-bottom: 1.5rem;
  text-align: center;
  color: #333;
`;

const AnalyticsGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
`;

const AnalyticsCard = styled.div`
  text-align: center;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 8px;
`;

const AnalyticsNumber = styled.div`
  font-size: 2rem;
  font-weight: bold;
  color: #667eea;
`;

const AnalyticsLabel = styled.div`
  font-size: 0.9rem;
  color: #666;
  margin-top: 0.5rem;
`;

const Analytics = ({ analytics }) => {
  return (
    <AnalyticsContainer>
      <SectionTitle>Store Analytics</SectionTitle>
      <AnalyticsGrid>
        <AnalyticsCard>
          <AnalyticsNumber>
            {analytics.totalProducts?.toLocaleString() || '0'}
          </AnalyticsNumber>
          <AnalyticsLabel>Total Products</AnalyticsLabel>
        </AnalyticsCard>
        <AnalyticsCard>
          <AnalyticsNumber>
            {analytics.totalOrders?.toLocaleString() || '0'}
          </AnalyticsNumber>
          <AnalyticsLabel>Total Orders</AnalyticsLabel>
        </AnalyticsCard>
        <AnalyticsCard>
          <AnalyticsNumber>
            {analytics.totalClicks?.toLocaleString() || '0'}
          </AnalyticsNumber>
          <AnalyticsLabel>Product Clicks</AnalyticsLabel>
        </AnalyticsCard>
        <AnalyticsCard>
          <AnalyticsNumber>
            {analytics.totalImpressions?.toLocaleString() || '0'}
          </AnalyticsNumber>
          <AnalyticsLabel>Impressions</AnalyticsLabel>
        </AnalyticsCard>
      </AnalyticsGrid>
    </AnalyticsContainer>
  );
};

export default Analytics;