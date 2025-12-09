-- ============================================
-- FIX REMAINING SECURITY WARNINGS
-- ============================================
-- This migration fixes:
-- 1. Function Search Path Mutable for count_orders_by_status
-- ============================================
-- Note: Leaked Password Protection must be enabled in Supabase Dashboard
-- See instructions in FIX_REMAINING_WARNINGS_README.md
-- ============================================

-- Fix: count_orders_by_status function
CREATE OR REPLACE FUNCTION count_orders_by_status()
RETURNS TABLE(
  pending BIGINT,
  assigned BIGINT,
  in_transit BIGINT,
  delivered BIGINT,
  cancelled BIGINT
) 
LANGUAGE plpgsql 
STABLE
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM orders WHERE status = 'pending')::BIGINT,
    (SELECT COUNT(*) FROM orders WHERE status = 'assigned')::BIGINT,
    (SELECT COUNT(*) FROM orders WHERE status = 'in_transit')::BIGINT,
    (SELECT COUNT(*) FROM orders WHERE status = 'delivered')::BIGINT,
    (SELECT COUNT(*) FROM orders WHERE status = 'cancelled')::BIGINT;
END;
$$;

-- ============================================
-- VERIFICATION
-- ============================================
-- After running this, check Supabase Dashboard → Database → Advisor
-- The "Function Search Path Mutable" warning should disappear
-- ============================================

