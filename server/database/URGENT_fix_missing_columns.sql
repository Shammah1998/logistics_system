-- ============================================
-- URGENT FIX: Add missing columns to production database
-- ============================================
-- Run this IMMEDIATELY in Supabase SQL Editor to fix 500 errors
-- ============================================

-- 1. Add full_name column to users table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'users' 
                   AND column_name = 'full_name') THEN
        ALTER TABLE public.users ADD COLUMN full_name TEXT;
        RAISE NOTICE 'Added full_name column to users table';
    ELSE
        RAISE NOTICE 'full_name column already exists';
    END IF;
END $$;

-- 2. Add total_distance column to orders table if it doesn't exist
-- (Code uses total_distance, schema has total_distance_km)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'orders' 
                   AND column_name = 'total_distance') THEN
        -- Add the column
        ALTER TABLE public.orders ADD COLUMN total_distance NUMERIC(10, 2);
        -- Copy data from total_distance_km if it exists
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'orders' 
                   AND column_name = 'total_distance_km') THEN
            UPDATE public.orders SET total_distance = total_distance_km WHERE total_distance IS NULL;
        END IF;
        RAISE NOTICE 'Added total_distance column to orders table';
    ELSE
        RAISE NOTICE 'total_distance column already exists';
    END IF;
END $$;

-- 3. Verify columns exist
SELECT 
    table_name, 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'orders')
AND column_name IN ('full_name', 'total_distance', 'total_distance_km')
ORDER BY table_name, column_name;

-- ============================================
-- After running this, redeploy the backend or wait for next request
-- The 500 errors should be resolved
-- ============================================

