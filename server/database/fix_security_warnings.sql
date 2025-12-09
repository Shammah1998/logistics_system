-- ============================================
-- FIX SECURITY WARNINGS: Function Search Path Mutable
-- ============================================
-- This migration fixes the security warning by setting a fixed search_path
-- for all database functions to prevent SQL injection vulnerabilities.
-- ============================================

-- Fix 1: update_updated_at_column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Fix 2: update_driver_credentials_updated_at
CREATE OR REPLACE FUNCTION update_driver_credentials_updated_at()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Fix 3: generate_order_number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    order_num TEXT;
    year_part TEXT;
    seq_num INTEGER;
BEGIN
    year_part := TO_CHAR(NOW(), 'YYYY');
    
    -- Get the next sequence number for this year
    SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM 10) AS INTEGER)), 0) + 1
    INTO seq_num
    FROM orders
    WHERE order_number LIKE 'ORD-' || year_part || '-%';
    
    order_num := 'ORD-' || year_part || '-' || LPAD(seq_num::TEXT, 6, '0');
    
    RETURN order_num;
END;
$$;

-- Fix 4: create_driver_wallet
CREATE OR REPLACE FUNCTION create_driver_wallet()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO wallets (driver_id, balance, pending_balance, total_earned)
    VALUES (NEW.id, 0, 0, 0);
    RETURN NEW;
END;
$$;

-- Fix 5: get_user_type
CREATE OR REPLACE FUNCTION get_user_type(user_uuid UUID)
RETURNS user_type_enum 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN (SELECT user_type FROM users WHERE id = user_uuid);
END;
$$;

-- Fix 6: handle_new_user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_phone TEXT;
BEGIN
    -- Extract phone from metadata, fallback to empty string if not provided
    user_phone := COALESCE(
        NEW.raw_user_meta_data->>'phone',
        NEW.raw_app_meta_data->>'phone',
        ''
    );
    
    -- If phone is still empty, use a placeholder (you can change this behavior)
    IF user_phone = '' OR user_phone IS NULL THEN
        user_phone := 'N/A';
    END IF;
    
    -- Insert into users table
    -- SECURITY DEFINER allows this to bypass RLS policies
    INSERT INTO public.users (id, email, phone, user_type)
    VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),
        user_phone,
        'customer'::user_type_enum  -- Default to customer, can be updated later by admin
    )
    ON CONFLICT (id) DO NOTHING;  -- Prevent errors if user already exists
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the auth signup
        RAISE WARNING 'Error creating user record: %', SQLERRM;
        RETURN NEW;
END;
$$;

