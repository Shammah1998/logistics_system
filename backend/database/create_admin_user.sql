-- Script to create an admin user manually
-- Run this in Supabase SQL Editor after setting up authentication
-- 
-- IMPORTANT: Replace the values below with your desired admin credentials
-- 1. First, create the user in Supabase Auth (Authentication > Users > Add User)
-- 2. Copy the user's UUID from auth.users
-- 3. Update the INSERT statement below with that UUID and your details
-- 4. Run this script

-- Example: Create admin user
-- Replace 'YOUR_USER_UUID_FROM_AUTH_USERS' with the actual UUID from auth.users
-- Replace 'admin@example.com' with your admin email
-- Replace '+254712345678' with your admin phone number

INSERT INTO public.users (id, email, phone, user_type)
VALUES (
    'YOUR_USER_UUID_FROM_AUTH_USERS'::UUID,  -- Replace with actual UUID from auth.users
    'admin@example.com',                      -- Replace with your admin email
    '+254712345678',                          -- Replace with your admin phone
    'admin'::user_type_enum
)
ON CONFLICT (id) DO UPDATE
SET user_type = 'admin'::user_type_enum;

-- After running this, you can log in with the admin credentials
-- and access the admin panel with full permissions

