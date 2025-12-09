-- ============================================
-- FIX RLS PERFORMANCE WARNINGS
-- ============================================
-- This migration fixes all RLS performance issues by:
-- 1. Replacing auth.uid() with (select auth.uid()) to prevent re-evaluation per row
-- 2. Optimizing get_user_type() calls
-- ============================================
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- DROP ALL EXISTING POLICIES
-- ============================================

-- Users table
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;

-- Companies table
DROP POLICY IF EXISTS "Customers can view own company" ON companies;
DROP POLICY IF EXISTS "Customers can insert own company" ON companies;
DROP POLICY IF EXISTS "Customers can update own company" ON companies;
DROP POLICY IF EXISTS "Admins can view all companies" ON companies;
DROP POLICY IF EXISTS "Admins can insert companies" ON companies;
DROP POLICY IF EXISTS "Admins can update all companies" ON companies;

-- Drivers table
DROP POLICY IF EXISTS "Drivers can view own profile" ON drivers;
DROP POLICY IF EXISTS "Drivers can update own profile" ON drivers;
DROP POLICY IF EXISTS "Admins can view all drivers" ON drivers;
DROP POLICY IF EXISTS "Admins can insert drivers" ON drivers;
DROP POLICY IF EXISTS "Admins can update all drivers" ON drivers;

-- Vehicles table
DROP POLICY IF EXISTS "Drivers can view own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Drivers can insert own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Drivers can update own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Admins can view all vehicles" ON vehicles;
DROP POLICY IF EXISTS "Admins can insert vehicles" ON vehicles;
DROP POLICY IF EXISTS "Admins can update all vehicles" ON vehicles;

-- Orders table
DROP POLICY IF EXISTS "Customers can view own orders" ON orders;
DROP POLICY IF EXISTS "Customers can insert own orders" ON orders;
DROP POLICY IF EXISTS "Customers can update own pending orders" ON orders;
DROP POLICY IF EXISTS "Drivers can view assigned orders" ON orders;
DROP POLICY IF EXISTS "Drivers can update assigned orders" ON orders;
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
DROP POLICY IF EXISTS "Admins can insert orders" ON orders;
DROP POLICY IF EXISTS "Admins can update all orders" ON orders;

-- Order items table
DROP POLICY IF EXISTS "Users can view order items for accessible orders" ON order_items;
DROP POLICY IF EXISTS "Customers can insert order items" ON order_items;
DROP POLICY IF EXISTS "Admins can insert order items" ON order_items;
DROP POLICY IF EXISTS "Admins can update order items" ON order_items;

-- Drops table
DROP POLICY IF EXISTS "Users can view drops for accessible orders" ON drops;
DROP POLICY IF EXISTS "Customers can insert drops" ON drops;
DROP POLICY IF EXISTS "Drivers can update drops for assigned orders" ON drops;
DROP POLICY IF EXISTS "Admins can manage all drops" ON drops;

-- PODs table
DROP POLICY IF EXISTS "Drivers can view own PODs" ON pods;
DROP POLICY IF EXISTS "Drivers can insert PODs" ON pods;
DROP POLICY IF EXISTS "Drivers can update own pending PODs" ON pods;
DROP POLICY IF EXISTS "Customers can view PODs for own orders" ON pods;
DROP POLICY IF EXISTS "Admins can view all PODs" ON pods;
DROP POLICY IF EXISTS "Admins can update all PODs" ON pods;

-- Wallets table
DROP POLICY IF EXISTS "Drivers can view own wallet" ON wallets;
DROP POLICY IF EXISTS "Admins can view all wallets" ON wallets;
DROP POLICY IF EXISTS "Admins can update all wallets" ON wallets;

-- Transactions table
DROP POLICY IF EXISTS "Drivers can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Admins can view all transactions" ON transactions;
DROP POLICY IF EXISTS "Admins can insert transactions" ON transactions;

-- Withdrawal requests table
DROP POLICY IF EXISTS "Drivers can view own withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "Drivers can insert own withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "Admins can view all withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "Admins can update all withdrawal requests" ON withdrawal_requests;

-- Price cards table
DROP POLICY IF EXISTS "Customers can view own company price cards" ON price_cards;
DROP POLICY IF EXISTS "Admins can view all price cards" ON price_cards;
DROP POLICY IF EXISTS "Admins can insert price cards" ON price_cards;
DROP POLICY IF EXISTS "Admins can update all price cards" ON price_cards;

-- Audit logs table
DROP POLICY IF EXISTS "Users can view own audit logs" ON audit_logs;
DROP POLICY IF EXISTS "Admins can view all audit logs" ON audit_logs;

-- Notifications table
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;

-- Driver credentials table (if exists)
DROP POLICY IF EXISTS "Admins can view driver credentials" ON driver_credentials;
DROP POLICY IF EXISTS "Admins can insert driver credentials" ON driver_credentials;
DROP POLICY IF EXISTS "Admins can update driver credentials" ON driver_credentials;
DROP POLICY IF EXISTS "Admins can delete driver credentials" ON driver_credentials;

-- ============================================
-- RECREATE POLICIES WITH OPTIMIZED AUTH CALLS
-- ============================================
-- All auth.uid() calls are wrapped in (select auth.uid()) to prevent re-evaluation per row
-- ============================================

-- ============================================
-- USERS TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING ((select auth.uid()) = id);

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING ((select auth.uid()) = id);

CREATE POLICY "Admins can view all users"
    ON users FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can update all users"
    ON users FOR UPDATE
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- COMPANIES TABLE POLICIES
-- ============================================

CREATE POLICY "Customers can view own company"
    ON companies FOR SELECT
    USING (
        id IN (
            SELECT company_id FROM users 
            WHERE id = (select auth.uid()) AND user_type = 'customer'
        )
    );

CREATE POLICY "Customers can insert own company"
    ON companies FOR INSERT
    WITH CHECK (true); -- Will be validated in application layer

CREATE POLICY "Customers can update own company"
    ON companies FOR UPDATE
    USING (
        id IN (
            SELECT company_id FROM users 
            WHERE id = (select auth.uid()) AND user_type = 'customer'
        )
    );

CREATE POLICY "Admins can view all companies"
    ON companies FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can insert companies"
    ON companies FOR INSERT
    WITH CHECK (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can update all companies"
    ON companies FOR UPDATE
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- DRIVERS TABLE POLICIES
-- ============================================

CREATE POLICY "Drivers can view own profile"
    ON drivers FOR SELECT
    USING (id = (select auth.uid()));

CREATE POLICY "Drivers can update own profile"
    ON drivers FOR UPDATE
    USING (id = (select auth.uid()));

CREATE POLICY "Admins can view all drivers"
    ON drivers FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can insert drivers"
    ON drivers FOR INSERT
    WITH CHECK (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can update all drivers"
    ON drivers FOR UPDATE
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- VEHICLES TABLE POLICIES
-- ============================================

CREATE POLICY "Drivers can view own vehicles"
    ON vehicles FOR SELECT
    USING (driver_id = (select auth.uid()));

CREATE POLICY "Drivers can insert own vehicles"
    ON vehicles FOR INSERT
    WITH CHECK (driver_id = (select auth.uid()));

CREATE POLICY "Drivers can update own vehicles"
    ON vehicles FOR UPDATE
    USING (driver_id = (select auth.uid()));

CREATE POLICY "Admins can view all vehicles"
    ON vehicles FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can insert vehicles"
    ON vehicles FOR INSERT
    WITH CHECK (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can update all vehicles"
    ON vehicles FOR UPDATE
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- ORDERS TABLE POLICIES
-- ============================================

CREATE POLICY "Customers can view own orders"
    ON orders FOR SELECT
    USING (customer_id = (select auth.uid()));

CREATE POLICY "Customers can insert own orders"
    ON orders FOR INSERT
    WITH CHECK (customer_id = (select auth.uid()));

CREATE POLICY "Customers can update own pending orders"
    ON orders FOR UPDATE
    USING (
        customer_id = (select auth.uid()) 
        AND status = 'pending'
    );

CREATE POLICY "Drivers can view assigned orders"
    ON orders FOR SELECT
    USING (driver_id = (select auth.uid()));

CREATE POLICY "Drivers can update assigned orders"
    ON orders FOR UPDATE
    USING (driver_id = (select auth.uid()));

CREATE POLICY "Admins can view all orders"
    ON orders FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can insert orders"
    ON orders FOR INSERT
    WITH CHECK (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can update all orders"
    ON orders FOR UPDATE
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- ORDER ITEMS TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view order items for accessible orders"
    ON order_items FOR SELECT
    USING (
        order_id IN (
            SELECT id FROM orders 
            WHERE customer_id = (select auth.uid()) 
               OR driver_id = (select auth.uid())
               OR get_user_type((select auth.uid())) = 'admin'
        )
    );

CREATE POLICY "Customers can insert order items"
    ON order_items FOR INSERT
    WITH CHECK (
        order_id IN (
            SELECT id FROM orders 
            WHERE customer_id = (select auth.uid()) AND status = 'pending'
        )
    );

CREATE POLICY "Admins can insert order items"
    ON order_items FOR INSERT
    WITH CHECK (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can update order items"
    ON order_items FOR UPDATE
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- DROPS TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view drops for accessible orders"
    ON drops FOR SELECT
    USING (
        order_id IN (
            SELECT id FROM orders 
            WHERE customer_id = (select auth.uid()) 
               OR driver_id = (select auth.uid())
               OR get_user_type((select auth.uid())) = 'admin'
        )
    );

CREATE POLICY "Customers can insert drops"
    ON drops FOR INSERT
    WITH CHECK (
        order_id IN (
            SELECT id FROM orders 
            WHERE customer_id = (select auth.uid()) AND status = 'pending'
        )
    );

CREATE POLICY "Drivers can update drops for assigned orders"
    ON drops FOR UPDATE
    USING (
        order_id IN (
            SELECT id FROM orders WHERE driver_id = (select auth.uid())
        )
    );

CREATE POLICY "Admins can manage all drops"
    ON drops FOR ALL
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- PODS TABLE POLICIES
-- ============================================

CREATE POLICY "Drivers can view own PODs"
    ON pods FOR SELECT
    USING (driver_id = (select auth.uid()));

CREATE POLICY "Drivers can insert PODs"
    ON pods FOR INSERT
    WITH CHECK (
        driver_id = (select auth.uid()) 
        AND order_id IN (
            SELECT id FROM orders WHERE driver_id = (select auth.uid())
        )
    );

CREATE POLICY "Drivers can update own pending PODs"
    ON pods FOR UPDATE
    USING (
        driver_id = (select auth.uid()) 
        AND status = 'pending'
    );

CREATE POLICY "Customers can view PODs for own orders"
    ON pods FOR SELECT
    USING (
        order_id IN (
            SELECT id FROM orders WHERE customer_id = (select auth.uid())
        )
    );

CREATE POLICY "Admins can view all PODs"
    ON pods FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can update all PODs"
    ON pods FOR UPDATE
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- WALLETS TABLE POLICIES
-- ============================================

CREATE POLICY "Drivers can view own wallet"
    ON wallets FOR SELECT
    USING (driver_id = (select auth.uid()));

CREATE POLICY "Admins can view all wallets"
    ON wallets FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can update all wallets"
    ON wallets FOR UPDATE
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- TRANSACTIONS TABLE POLICIES
-- ============================================

CREATE POLICY "Drivers can view own transactions"
    ON transactions FOR SELECT
    USING (
        wallet_id IN (
            SELECT id FROM wallets WHERE driver_id = (select auth.uid())
        )
    );

CREATE POLICY "Admins can view all transactions"
    ON transactions FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can insert transactions"
    ON transactions FOR INSERT
    WITH CHECK (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- WITHDRAWAL REQUESTS TABLE POLICIES
-- ============================================

CREATE POLICY "Drivers can view own withdrawal requests"
    ON withdrawal_requests FOR SELECT
    USING (driver_id = (select auth.uid()));

CREATE POLICY "Drivers can insert own withdrawal requests"
    ON withdrawal_requests FOR INSERT
    WITH CHECK (driver_id = (select auth.uid()));

CREATE POLICY "Admins can view all withdrawal requests"
    ON withdrawal_requests FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can update all withdrawal requests"
    ON withdrawal_requests FOR UPDATE
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- PRICE CARDS TABLE POLICIES
-- ============================================

CREATE POLICY "Customers can view own company price cards"
    ON price_cards FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM users 
            WHERE id = (select auth.uid()) AND user_type = 'customer'
        )
        OR company_id IS NULL -- Default price cards
    );

CREATE POLICY "Admins can view all price cards"
    ON price_cards FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can insert price cards"
    ON price_cards FOR INSERT
    WITH CHECK (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can update all price cards"
    ON price_cards FOR UPDATE
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- AUDIT LOGS TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view own audit logs"
    ON audit_logs FOR SELECT
    USING (user_id = (select auth.uid()));

CREATE POLICY "Admins can view all audit logs"
    ON audit_logs FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- NOTIFICATIONS TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    USING (user_id = (select auth.uid()));

CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    USING (user_id = (select auth.uid()));

-- ============================================
-- DRIVER CREDENTIALS TABLE POLICIES (if exists)
-- ============================================

CREATE POLICY "Admins can view driver credentials"
    ON driver_credentials FOR SELECT
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can insert driver credentials"
    ON driver_credentials FOR INSERT
    WITH CHECK (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can update driver credentials"
    ON driver_credentials FOR UPDATE
    USING (get_user_type((select auth.uid())) = 'admin');

CREATE POLICY "Admins can delete driver credentials"
    ON driver_credentials FOR DELETE
    USING (get_user_type((select auth.uid())) = 'admin');

-- ============================================
-- VERIFICATION
-- ============================================
-- After running this migration, check Supabase Dashboard → Database → Policies
-- All policies should be recreated with optimized auth calls
-- The performance warnings should disappear after a few minutes
-- ============================================

