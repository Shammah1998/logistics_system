-- Script to fix missing user records
-- This will create records in public.users for any users in auth.users that don't have a record

-- First, check which users are missing
SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data->>'phone' as phone,
    au.created_at
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- Insert missing users into public.users table
INSERT INTO public.users (id, email, phone, user_type)
SELECT 
    au.id,
    COALESCE(au.email, ''),
    COALESCE(
        au.raw_user_meta_data->>'phone',
        au.raw_app_meta_data->>'phone',
        'N/A'
    ),
    'customer'::user_type_enum  -- Default to customer
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- Verify the fix
SELECT 
    'Total auth.users' as source,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Total public.users' as source,
    COUNT(*) as count
FROM public.users;

