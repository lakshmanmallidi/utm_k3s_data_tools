#!/bin/bash

# Generate Test Impressions Data for MyKart Debezium CDC
# This script inserts sample impression data to test the Kafka connector

echo "📊 Generating MyKart Impressions Test Data"
echo "=========================================="

# Insert sample impressions data
kubectl exec postgres-wal-0 -- psql -U admin -d mykart -c "
-- Insert test impression events
INSERT INTO impressions (user_id, product_id, session_id, created_at) VALUES
('user123', 1, 'session_abc123', NOW()),
('user456', 2, 'session_def456', NOW()),
('user789', 3, 'session_ghi789', NOW()),
('user123', 5, 'session_abc123', NOW() + INTERVAL '1 second'),
('user456', 8, 'session_def456', NOW() + INTERVAL '2 seconds'),
('user999', 12, 'session_xyz999', NOW() + INTERVAL '3 seconds');

-- Show the inserted data
SELECT 'Inserted impressions data:' as status;
SELECT * FROM impressions ORDER BY created_at DESC LIMIT 10;

-- Also insert some clicks and cart events for testing
INSERT INTO clicks (user_id, product_id, session_id, created_at) VALUES
('user123', 1, 'session_abc123', NOW() + INTERVAL '5 seconds'),
('user456', 2, 'session_def456', NOW() + INTERVAL '6 seconds');

INSERT INTO cart_events (user_id, product_id, session_id, event_type, quantity, created_at) VALUES
('user123', 1, 'session_abc123', 'add', 1, NOW() + INTERVAL '10 seconds'),
('user456', 2, 'session_def456', 'add', 2, NOW() + INTERVAL '11 seconds');

SELECT 'Test data generation complete!' as status;
SELECT 
    'impressions' as table_name, COUNT(*) as total_records 
FROM impressions
UNION ALL
SELECT 
    'clicks' as table_name, COUNT(*) as total_records 
FROM clicks
UNION ALL
SELECT 
    'cart_events' as table_name, COUNT(*) as total_records 
FROM cart_events;
"

echo
echo "✅ Test data generated successfully!"
echo "📊 Check Kafka topics for CDC events:"
echo "   • mykart.impressions - for impression events"
echo "   • mykart.clicks - for click events"  
echo "   • mykart.cart_events - for cart events"