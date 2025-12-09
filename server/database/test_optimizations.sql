-- ============================================
-- TEST QUERIES FOR DATABASE OPTIMIZATIONS
-- ============================================
-- Run these queries to verify indexes are being used
-- ============================================

-- Test 1: Customer orders with status filter (should use idx_orders_customer_status_created)
EXPLAIN ANALYZE
SELECT id, order_number, status, total_price, created_at
FROM orders
WHERE customer_id = (SELECT id FROM users WHERE user_type = 'customer' LIMIT 1)
  AND status = 'pending'
ORDER BY created_at DESC
LIMIT 10;

-- Expected: Index Scan using idx_orders_customer_status_created
-- If you see "Seq Scan", the index is not being used

-- Test 2: Driver orders (should use idx_orders_driver_status_created)
EXPLAIN ANALYZE
SELECT id, status, total_price, created_at
FROM orders
WHERE driver_id = (SELECT id FROM drivers LIMIT 1)
  AND status = 'assigned'
ORDER BY created_at DESC
LIMIT 10;

-- Expected: Index Scan using idx_orders_driver_status_created

-- Test 3: Orders by status (should use idx_orders_status_created)
EXPLAIN ANALYZE
SELECT id, status, created_at
FROM orders
WHERE status = 'delivered'
ORDER BY created_at DESC
LIMIT 50;

-- Expected: Index Scan using idx_orders_status_created

-- Test 4: User lookup by phone and type (should use idx_users_phone_type)
EXPLAIN ANALYZE
SELECT id, email, full_name, user_type
FROM users
WHERE phone = '+254712345678'
  AND user_type = 'driver';

-- Expected: Index Scan using idx_users_phone_type

-- Test 5: Active drivers (should use idx_drivers_active partial index)
EXPLAIN ANALYZE
SELECT id, status, created_at
FROM drivers
WHERE status = 'active'
ORDER BY created_at DESC;

-- Expected: Index Scan using idx_drivers_active

-- Test 6: Dashboard revenue aggregation (should use idx_orders_delivered)
EXPLAIN ANALYZE
SELECT SUM(total_price) as total_revenue
FROM orders
WHERE status = 'delivered';

-- Expected: Index Scan using idx_orders_delivered

-- Test 7: Drops for order (should use idx_drops_order_sequence)
EXPLAIN ANALYZE
SELECT id, recipient_name, drop_sequence
FROM drops
WHERE order_id = (SELECT id FROM orders LIMIT 1)
ORDER BY drop_sequence;

-- Expected: Index Scan using idx_drops_order_sequence

-- Test 8: Pending PODs (should use idx_pods_pending)
EXPLAIN ANALYZE
SELECT id, status, created_at
FROM pods
WHERE status = 'pending'
ORDER BY created_at DESC;

-- Expected: Index Scan using idx_pods_pending

-- ============================================
-- VERIFY INDEXES EXIST
-- ============================================

SELECT 
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- ============================================
-- VERIFY FUNCTIONS EXIST
-- ============================================

SELECT 
  routine_name,
  routine_type,
  data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('sum_orders_revenue', 'sum_orders_revenue_range', 'count_orders_by_status')
ORDER BY routine_name;

-- ============================================
-- CHECK INDEX USAGE STATISTICS
-- ============================================

SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan as times_used,
  idx_tup_read as tuples_read,
  idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%'
ORDER BY idx_scan DESC;

-- ============================================
-- CHECK TABLE SIZES (to verify indexes are helping)
-- ============================================

SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
  pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) AS indexes_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

