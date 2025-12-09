-- ============================================
-- DATABASE OPTIMIZATION: Indexes & Query Performance
-- ============================================
-- This migration adds composite indexes and optimizes frequently queried columns
-- Run this in Supabase SQL Editor after analyzing query patterns
-- ============================================

-- ============================================
-- COMPOSITE INDEXES FOR COMMON QUERY PATTERNS
-- ============================================

-- Orders: Customer orders with status filter and date sorting (most common query)
-- Query pattern: WHERE customer_id = ? AND status = ? ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_orders_customer_status_created 
ON orders(customer_id, status, created_at DESC);

-- Orders: Driver orders with status filter and date sorting
-- Query pattern: WHERE driver_id = ? AND status = ? ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_orders_driver_status_created 
ON orders(driver_id, status, created_at DESC);

-- Orders: Status and date for dashboard/filtering
-- Query pattern: WHERE status = ? ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_orders_status_created 
ON orders(status, created_at DESC);

-- Orders: Date range queries for dashboard (today, monthly)
-- Query pattern: WHERE created_at >= ? AND status = ?
CREATE INDEX IF NOT EXISTS idx_orders_created_status 
ON orders(created_at DESC, status);

-- Orders: Revenue queries (delivered orders with date range)
-- Query pattern: WHERE status = 'delivered' AND created_at >= ?
CREATE INDEX IF NOT EXISTS idx_orders_delivered_created 
ON orders(status, created_at DESC) 
WHERE status = 'delivered';

-- Users: Phone and user_type lookup (for driver login)
-- Query pattern: WHERE phone = ? AND user_type = 'driver'
CREATE INDEX IF NOT EXISTS idx_users_phone_type 
ON users(phone, user_type);

-- Users: User type filtering (for customer/driver lists)
-- Query pattern: WHERE user_type = ? ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_users_type_created 
ON users(user_type, created_at DESC);

-- Drivers: Status filtering (active drivers list)
-- Query pattern: WHERE status = 'active'
CREATE INDEX IF NOT EXISTS idx_drivers_status_created 
ON drivers(status, created_at DESC);

-- Drops: Order and sequence (for order details)
-- Query pattern: WHERE order_id = ? ORDER BY drop_sequence
CREATE INDEX IF NOT EXISTS idx_drops_order_sequence 
ON drops(order_id, drop_sequence);

-- Drops: Status filtering
-- Query pattern: WHERE order_id = ? AND status = ?
CREATE INDEX IF NOT EXISTS idx_drops_order_status 
ON drops(order_id, status);

-- PODs: Status and date (pending PODs list)
-- Query pattern: WHERE status = 'pending' ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_pods_status_created 
ON pods(status, created_at DESC);

-- PODs: Driver and status (driver's PODs)
-- Query pattern: WHERE driver_id = ? AND status = ?
CREATE INDEX IF NOT EXISTS idx_pods_driver_status 
ON pods(driver_id, status);

-- Transactions: Wallet and date (transaction history)
-- Query pattern: WHERE wallet_id = ? ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_transactions_wallet_created 
ON transactions(wallet_id, created_at DESC);

-- Transactions: Order lookup
-- Query pattern: WHERE order_id = ?
CREATE INDEX IF NOT EXISTS idx_transactions_order_id 
ON transactions(order_id) 
WHERE order_id IS NOT NULL;

-- Withdrawal requests: Driver and status
-- Query pattern: WHERE driver_id = ? AND status = ?
CREATE INDEX IF NOT EXISTS idx_withdrawal_driver_status 
ON withdrawal_requests(driver_id, status);

-- Price cards: Active cards lookup (pricing service)
-- Query pattern: WHERE vehicle_type = ? AND pricing_mode = ? AND is_active = true
CREATE INDEX IF NOT EXISTS idx_price_cards_active_lookup 
ON price_cards(vehicle_type, pricing_mode, is_active, valid_from DESC) 
WHERE is_active = true;

-- ============================================
-- PARTIAL INDEXES FOR COMMON FILTERS
-- ============================================

-- Active drivers only (most common filter)
CREATE INDEX IF NOT EXISTS idx_drivers_active 
ON drivers(id, created_at DESC) 
WHERE status = 'active';

-- Pending orders only
CREATE INDEX IF NOT EXISTS idx_orders_pending 
ON orders(id, created_at DESC) 
WHERE status = 'pending';

-- Delivered orders (for revenue calculations)
CREATE INDEX IF NOT EXISTS idx_orders_delivered 
ON orders(id, total_price, created_at DESC) 
WHERE status = 'delivered';

-- Pending PODs only
CREATE INDEX IF NOT EXISTS idx_pods_pending 
ON pods(id, created_at DESC) 
WHERE status = 'pending';

-- ============================================
-- COVERING INDEXES (Include frequently selected columns)
-- ============================================

-- Orders: Covering index for order list queries
-- Includes: id, order_number, status, total_amount, created_at, customer_id, driver_id
CREATE INDEX IF NOT EXISTS idx_orders_list_covering 
ON orders(status, created_at DESC) 
INCLUDE (id, order_number, total_price, customer_id, driver_id);

-- Users: Covering index for user lookups
-- Includes: id, email, phone, full_name, user_type
CREATE INDEX IF NOT EXISTS idx_users_lookup_covering 
ON users(user_type, phone) 
INCLUDE (id, email, full_name);

-- ============================================
-- ANALYZE TABLES (Update statistics for query planner)
-- ============================================

ANALYZE users;
ANALYZE drivers;
ANALYZE orders;
ANALYZE drops;
ANALYZE pods;
ANALYZE wallets;
ANALYZE transactions;
ANALYZE withdrawal_requests;
ANALYZE price_cards;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Run these to verify indexes are being used:
-- 
-- EXPLAIN ANALYZE 
-- SELECT * FROM orders 
-- WHERE customer_id = 'some-uuid' 
-- AND status = 'pending' 
-- ORDER BY created_at DESC 
-- LIMIT 10;
-- 
-- Should show: Index Scan using idx_orders_customer_status_created

