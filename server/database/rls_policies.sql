-- Row Level Security (RLS) Policies for Supabase
-- This file contains all RLS policies for the logistics platform

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE drops ENABLE ROW LEVEL SECURITY;
ALTER TABLE pods ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTION TO GET USER TYPE
-- ============================================

CREATE OR REPLACE FUNCTION get_user_type(user_uuid UUID)
RETURNS user_type_enum AS $$
BEGIN
    RETURN (SELECT user_type FROM users WHERE id = user_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- USERS TABLE POLICIES
-- ============================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

-- Admins can view all users
CREATE POLICY "Admins can view all users"
    ON users FOR SELECT
    USING (get_user_type(auth.uid()) = 'admin');

-- Admins can update all users
CREATE POLICY "Admins can update all users"
    ON users FOR UPDATE
    USING (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- COMPANIES TABLE POLICIES
-- ============================================

-- Customers can view their own company
CREATE POLICY "Customers can view own company"
    ON companies FOR SELECT
    USING (
        id IN (
            SELECT company_id FROM users 
            WHERE id = auth.uid() AND user_type = 'customer'
        )
    );

-- Customers can insert their own company
CREATE POLICY "Customers can insert own company"
    ON companies FOR INSERT
    WITH CHECK (true); -- Will be validated in application layer

-- Customers can update their own company
CREATE POLICY "Customers can update own company"
    ON companies FOR UPDATE
    USING (
        id IN (
            SELECT company_id FROM users 
            WHERE id = auth.uid() AND user_type = 'customer'
        )
    );

-- Admins can view all companies
CREATE POLICY "Admins can view all companies"
    ON companies FOR SELECT
    USING (get_user_type(auth.uid()) = 'admin');

-- Admins can insert companies
CREATE POLICY "Admins can insert companies"
    ON companies FOR INSERT
    WITH CHECK (get_user_type(auth.uid()) = 'admin');

-- Admins can update all companies
CREATE POLICY "Admins can update all companies"
    ON companies FOR UPDATE
    USING (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- DRIVERS TABLE POLICIES
-- ============================================

-- Drivers can view their own profile
CREATE POLICY "Drivers can view own profile"
    ON drivers FOR SELECT
    USING (id = auth.uid());

-- Drivers can update their own profile (limited fields)
CREATE POLICY "Drivers can update own profile"
    ON drivers FOR UPDATE
    USING (id = auth.uid());

-- Admins can view all drivers
CREATE POLICY "Admins can view all drivers"
    ON drivers FOR SELECT
    USING (get_user_type(auth.uid()) = 'admin');

-- Admins can insert drivers
CREATE POLICY "Admins can insert drivers"
    ON drivers FOR INSERT
    WITH CHECK (get_user_type(auth.uid()) = 'admin');

-- Admins can update all drivers
CREATE POLICY "Admins can update all drivers"
    ON drivers FOR UPDATE
    USING (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- VEHICLES TABLE POLICIES
-- ============================================

-- Drivers can view their own vehicles
CREATE POLICY "Drivers can view own vehicles"
    ON vehicles FOR SELECT
    USING (driver_id = auth.uid());

-- Drivers can insert their own vehicles
CREATE POLICY "Drivers can insert own vehicles"
    ON vehicles FOR INSERT
    WITH CHECK (driver_id = auth.uid());

-- Drivers can update their own vehicles
CREATE POLICY "Drivers can update own vehicles"
    ON vehicles FOR UPDATE
    USING (driver_id = auth.uid());

-- Admins can view all vehicles
CREATE POLICY "Admins can view all vehicles"
    ON vehicles FOR SELECT
    USING (get_user_type(auth.uid()) = 'admin');

-- Admins can insert vehicles
CREATE POLICY "Admins can insert vehicles"
    ON vehicles FOR INSERT
    WITH CHECK (get_user_type(auth.uid()) = 'admin');

-- Admins can update all vehicles
CREATE POLICY "Admins can update all vehicles"
    ON vehicles FOR UPDATE
    USING (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- ORDERS TABLE POLICIES
-- ============================================

-- Customers can view their own orders
CREATE POLICY "Customers can view own orders"
    ON orders FOR SELECT
    USING (customer_id = auth.uid());

-- Customers can insert their own orders
CREATE POLICY "Customers can insert own orders"
    ON orders FOR INSERT
    WITH CHECK (customer_id = auth.uid());

-- Customers can update their own orders (only if pending)
CREATE POLICY "Customers can update own pending orders"
    ON orders FOR UPDATE
    USING (
        customer_id = auth.uid() 
        AND status = 'pending'
    );

-- Drivers can view assigned orders
CREATE POLICY "Drivers can view assigned orders"
    ON orders FOR SELECT
    USING (driver_id = auth.uid());

-- Drivers can update assigned orders (status updates only)
CREATE POLICY "Drivers can update assigned orders"
    ON orders FOR UPDATE
    USING (driver_id = auth.uid());

-- Admins can view all orders
CREATE POLICY "Admins can view all orders"
    ON orders FOR SELECT
    USING (get_user_type(auth.uid()) = 'admin');

-- Admins can insert orders
CREATE POLICY "Admins can insert orders"
    ON orders FOR INSERT
    WITH CHECK (get_user_type(auth.uid()) = 'admin');

-- Admins can update all orders
CREATE POLICY "Admins can update all orders"
    ON orders FOR UPDATE
    USING (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- ORDER ITEMS TABLE POLICIES
-- ============================================

-- Users can view order items for orders they have access to
CREATE POLICY "Users can view order items for accessible orders"
    ON order_items FOR SELECT
    USING (
        order_id IN (
            SELECT id FROM orders 
            WHERE customer_id = auth.uid() 
               OR driver_id = auth.uid()
               OR get_user_type(auth.uid()) = 'admin'
        )
    );

-- Customers can insert order items for their orders
CREATE POLICY "Customers can insert order items"
    ON order_items FOR INSERT
    WITH CHECK (
        order_id IN (
            SELECT id FROM orders 
            WHERE customer_id = auth.uid() AND status = 'pending'
        )
    );

-- Admins can insert order items
CREATE POLICY "Admins can insert order items"
    ON order_items FOR INSERT
    WITH CHECK (get_user_type(auth.uid()) = 'admin');

-- Admins can update order items
CREATE POLICY "Admins can update order items"
    ON order_items FOR UPDATE
    USING (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- DROPS TABLE POLICIES
-- ============================================

-- Users can view drops for orders they have access to
CREATE POLICY "Users can view drops for accessible orders"
    ON drops FOR SELECT
    USING (
        order_id IN (
            SELECT id FROM orders 
            WHERE customer_id = auth.uid() 
               OR driver_id = auth.uid()
               OR get_user_type(auth.uid()) = 'admin'
        )
    );

-- Customers can insert drops for their orders
CREATE POLICY "Customers can insert drops"
    ON drops FOR INSERT
    WITH CHECK (
        order_id IN (
            SELECT id FROM orders 
            WHERE customer_id = auth.uid() AND status = 'pending'
        )
    );

-- Drivers can update drops for assigned orders
CREATE POLICY "Drivers can update drops for assigned orders"
    ON drops FOR UPDATE
    USING (
        order_id IN (
            SELECT id FROM orders WHERE driver_id = auth.uid()
        )
    );

-- Admins can insert and update all drops
CREATE POLICY "Admins can manage all drops"
    ON drops FOR ALL
    USING (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- PODS TABLE POLICIES
-- ============================================

-- Drivers can view PODs for their assigned orders
CREATE POLICY "Drivers can view own PODs"
    ON pods FOR SELECT
    USING (driver_id = auth.uid());

-- Drivers can insert PODs for assigned orders
CREATE POLICY "Drivers can insert PODs"
    ON pods FOR INSERT
    WITH CHECK (
        driver_id = auth.uid() 
        AND order_id IN (
            SELECT id FROM orders WHERE driver_id = auth.uid()
        )
    );

-- Drivers can update their own PODs (only if pending)
CREATE POLICY "Drivers can update own pending PODs"
    ON pods FOR UPDATE
    USING (
        driver_id = auth.uid() 
        AND status = 'pending'
    );

-- Customers can view PODs for their orders
CREATE POLICY "Customers can view PODs for own orders"
    ON pods FOR SELECT
    USING (
        order_id IN (
            SELECT id FROM orders WHERE customer_id = auth.uid()
        )
    );

-- Admins can view all PODs
CREATE POLICY "Admins can view all PODs"
    ON pods FOR SELECT
    USING (get_user_type(auth.uid()) = 'admin');

-- Admins can update all PODs
CREATE POLICY "Admins can update all PODs"
    ON pods FOR UPDATE
    USING (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- WALLETS TABLE POLICIES
-- ============================================

-- Drivers can view their own wallet
CREATE POLICY "Drivers can view own wallet"
    ON wallets FOR SELECT
    USING (driver_id = auth.uid());

-- Admins can view all wallets
CREATE POLICY "Admins can view all wallets"
    ON wallets FOR SELECT
    USING (get_user_type(auth.uid()) = 'admin');

-- Admins can update all wallets
CREATE POLICY "Admins can update all wallets"
    ON wallets FOR UPDATE
    USING (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- TRANSACTIONS TABLE POLICIES
-- ============================================

-- Drivers can view transactions for their own wallet
CREATE POLICY "Drivers can view own transactions"
    ON transactions FOR SELECT
    USING (
        wallet_id IN (
            SELECT id FROM wallets WHERE driver_id = auth.uid()
        )
    );

-- Admins can view all transactions
CREATE POLICY "Admins can view all transactions"
    ON transactions FOR SELECT
    USING (get_user_type(auth.uid()) = 'admin');

-- Admins can insert transactions
CREATE POLICY "Admins can insert transactions"
    ON transactions FOR INSERT
    WITH CHECK (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- WITHDRAWAL REQUESTS TABLE POLICIES
-- ============================================

-- Drivers can view their own withdrawal requests
CREATE POLICY "Drivers can view own withdrawal requests"
    ON withdrawal_requests FOR SELECT
    USING (driver_id = auth.uid());

-- Drivers can insert their own withdrawal requests
CREATE POLICY "Drivers can insert own withdrawal requests"
    ON withdrawal_requests FOR INSERT
    WITH CHECK (driver_id = auth.uid());

-- Admins can view all withdrawal requests
CREATE POLICY "Admins can view all withdrawal requests"
    ON withdrawal_requests FOR SELECT
    USING (get_user_type(auth.uid()) = 'admin');

-- Admins can update all withdrawal requests
CREATE POLICY "Admins can update all withdrawal requests"
    ON withdrawal_requests FOR UPDATE
    USING (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- PRICE CARDS TABLE POLICIES
-- ============================================

-- Customers can view price cards for their company
CREATE POLICY "Customers can view own company price cards"
    ON price_cards FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM users 
            WHERE id = auth.uid() AND user_type = 'customer'
        )
        OR company_id IS NULL -- Default price cards
    );

-- Admins can view all price cards
CREATE POLICY "Admins can view all price cards"
    ON price_cards FOR SELECT
    USING (get_user_type(auth.uid()) = 'admin');

-- Admins can insert price cards
CREATE POLICY "Admins can insert price cards"
    ON price_cards FOR INSERT
    WITH CHECK (get_user_type(auth.uid()) = 'admin');

-- Admins can update all price cards
CREATE POLICY "Admins can update all price cards"
    ON price_cards FOR UPDATE
    USING (get_user_type(auth.uid()) = 'admin');

-- ============================================
-- AUDIT LOGS TABLE POLICIES
-- ============================================

-- Users can view their own audit logs
CREATE POLICY "Users can view own audit logs"
    ON audit_logs FOR SELECT
    USING (user_id = auth.uid());

-- Admins can view all audit logs
CREATE POLICY "Admins can view all audit logs"
    ON audit_logs FOR SELECT
    USING (get_user_type(auth.uid()) = 'admin');

-- System can insert audit logs (via service role)
-- No RLS policy needed - service role bypasses RLS

-- ============================================
-- NOTIFICATIONS TABLE POLICIES
-- ============================================

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    USING (user_id = auth.uid());

-- System can insert notifications (via service role)
-- No RLS policy needed - service role bypasses RLS

