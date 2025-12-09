-- ============================================
-- AGGREGATION FUNCTIONS FOR DASHBOARD OPTIMIZATION
-- ============================================
-- These functions use SQL aggregation instead of fetching all rows
-- Significantly faster for large datasets
-- ============================================

-- Function to sum revenue for orders with specific status
-- OPTIMIZED: Uses aggregation instead of fetching all rows
CREATE OR REPLACE FUNCTION sum_orders_revenue(order_status TEXT)
RETURNS NUMERIC 
LANGUAGE plpgsql 
STABLE
SET search_path = public
AS $$
BEGIN
  RETURN COALESCE(
    (SELECT SUM(total_price) 
     FROM orders 
     WHERE status = order_status::order_status_enum),
    0
  );
END;
$$;

-- Function to sum revenue for orders with status and date range
-- OPTIMIZED: Uses aggregation with date filter
CREATE OR REPLACE FUNCTION sum_orders_revenue_range(
  order_status TEXT,
  start_date TIMESTAMPTZ
)
RETURNS NUMERIC 
LANGUAGE plpgsql 
STABLE
SET search_path = public
AS $$
BEGIN
  RETURN COALESCE(
    (SELECT SUM(total_price) 
     FROM orders 
     WHERE status = order_status::order_status_enum
       AND created_at >= start_date),
    0
  );
END;
$$;

-- Function to count orders by status (more efficient than fetching all)
CREATE OR REPLACE FUNCTION count_orders_by_status()
RETURNS TABLE(
  pending BIGINT,
  assigned BIGINT,
  in_transit BIGINT,
  delivered BIGINT,
  cancelled BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM orders WHERE status = 'pending')::BIGINT,
    (SELECT COUNT(*) FROM orders WHERE status = 'assigned')::BIGINT,
    (SELECT COUNT(*) FROM orders WHERE status = 'in_transit')::BIGINT,
    (SELECT COUNT(*) FROM orders WHERE status = 'delivered')::BIGINT,
    (SELECT COUNT(*) FROM orders WHERE status = 'cancelled')::BIGINT;
END;
$$ LANGUAGE plpgsql STABLE;

