import express from 'express';
import { authenticate, requireUserType } from '../middleware/auth.js';
import { supabase } from '../server.js';
import { logger } from '../utils/logger.js';
import { cache, CacheTTL, CacheKeys } from '../services/cacheService.js';

const router = express.Router();

// Helper function to fetch dashboard stats from database
// OPTIMIZED: Uses aggregation queries instead of fetching all data
async function fetchDashboardStats() {
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  const monthStart = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
  
  // Run optimized queries in parallel
  const [
    totalOrdersResult,
    ordersByStatusResult,
    activeDriversResult,
    totalDriversResult,
    totalCustomersResult,
    totalRevenueResult,
    monthlyRevenueResult,
    pendingPODsResult,
    todayOrdersResult
  ] = await Promise.all([
    // Total orders count (head: true = count only, no data)
    supabase.from('orders').select('*', { count: 'exact', head: true }),
    
    // Orders by status - use RPC for aggregation (more efficient)
    // Fallback: count each status separately if RPC not available
    Promise.all([
      supabase.from('orders').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
      supabase.from('orders').select('*', { count: 'exact', head: true }).eq('status', 'assigned'),
      supabase.from('orders').select('*', { count: 'exact', head: true }).eq('status', 'in_transit'),
      supabase.from('orders').select('*', { count: 'exact', head: true }).eq('status', 'delivered'),
      supabase.from('orders').select('*', { count: 'exact', head: true }).eq('status', 'cancelled')
    ]),
    
    // Active drivers count
    supabase.from('drivers').select('*', { count: 'exact', head: true }).eq('status', 'active'),
    
    // Total drivers count
    supabase.from('drivers').select('*', { count: 'exact', head: true }),
    
    // Total customers count
    supabase.from('users').select('*', { count: 'exact', head: true }).eq('user_type', 'customer'),
    
    // Total revenue - use aggregation query
    supabase.rpc('sum_orders_revenue', { order_status: 'delivered' }).catch(() => {
      // Fallback if RPC doesn't exist - use select with aggregation
      return supabase.from('orders').select('total_price').eq('status', 'delivered');
    }),
    
    // Monthly revenue - use aggregation query
    supabase.rpc('sum_orders_revenue_range', { 
      order_status: 'delivered',
      start_date: monthStart.toISOString()
    }).catch(() => {
      // Fallback if RPC doesn't exist
      return supabase.from('orders')
        .select('total_price')
        .eq('status', 'delivered')
        .gte('created_at', monthStart.toISOString());
    }),
    
    // Pending PODs count
    supabase.from('pods').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
    
    // Today's orders count
    supabase.from('orders').select('*', { count: 'exact', head: true }).gte('created_at', todayStart.toISOString())
  ]);

  // Process status counts from parallel queries
  const statusCounts = {
    pending: ordersByStatusResult[0]?.count || 0,
    assigned: ordersByStatusResult[1]?.count || 0,
    in_transit: ordersByStatusResult[2]?.count || 0,
    delivered: ordersByStatusResult[3]?.count || 0,
    cancelled: ordersByStatusResult[4]?.count || 0
  };

  // Calculate revenue (handle both RPC and fallback responses)
  let totalRevenue = 0;
  let monthlyRevenue = 0;
  
  if (totalRevenueResult.data) {
    if (typeof totalRevenueResult.data === 'number') {
      // RPC returned number directly
      totalRevenue = totalRevenueResult.data;
    } else if (Array.isArray(totalRevenueResult.data)) {
      // Fallback: sum array of orders
      totalRevenue = totalRevenueResult.data.reduce((sum, order) => sum + (order.total_price || 0), 0);
    }
  }
  
  if (monthlyRevenueResult.data) {
    if (typeof monthlyRevenueResult.data === 'number') {
      // RPC returned number directly
      monthlyRevenue = monthlyRevenueResult.data;
    } else if (Array.isArray(monthlyRevenueResult.data)) {
      // Fallback: sum array of orders
      monthlyRevenue = monthlyRevenueResult.data.reduce((sum, order) => sum + (order.total_price || 0), 0);
    }
  }

  return {
    orders: {
      total: totalOrdersResult.count || 0,
      today: todayOrdersResult.count || 0,
      pending: statusCounts.pending,
      assigned: statusCounts.assigned,
      inTransit: statusCounts.in_transit,
      delivered: statusCounts.delivered,
      cancelled: statusCounts.cancelled
    },
    drivers: {
      total: totalDriversResult.count || 0,
      active: activeDriversResult.count || 0
    },
    customers: {
      total: totalCustomersResult.count || 0
    },
    revenue: {
      total: totalRevenue,
      monthly: monthlyRevenue
    },
    pods: {
      pending: pendingPODsResult.count || 0
    }
  };
}

// Get dashboard statistics - admins only (CACHED)
router.get('/stats', authenticate, requireUserType('admin'), async (req, res, next) => {
  try {
    const cacheKey = cache.generateKey(CacheKeys.DASHBOARD, 'stats');
    
    // Try to get from cache or fetch fresh
    const { data, fromCache } = await cache.getOrSet(
      cacheKey,
      fetchDashboardStats,
      CacheTTL.DASHBOARD_STATS
    );

    res.json({
      success: true,
      data,
      _meta: {
        cached: fromCache,
        cacheKey: process.env.NODE_ENV === 'development' ? cacheKey : undefined
      }
    });
  } catch (error) {
    logger.error('Error fetching dashboard stats', { error: error.message });
    next(error);
  }
});

// Get recent activity - admins only (CACHED with shorter TTL)
router.get('/activity', authenticate, requireUserType('admin'), async (req, res, next) => {
  try {
    const { limit = 10 } = req.query;
    const cacheKey = cache.generateKey(CacheKeys.DASHBOARD, 'activity', limit);

    const { data, fromCache } = await cache.getOrSet(
      cacheKey,
      async () => {
        const { data: recentOrders } = await supabase
          .from('orders')
          .select(`
            id,
            order_number,
            status,
            total_price,
            created_at,
            users!customer_id (
              full_name
            )
          `)
          .order('created_at', { ascending: false })
          .limit(parseInt(limit));

        return (recentOrders || []).map(order => ({
          id: order.id,
          type: 'order',
          description: `New order ${order.order_number || order.id.slice(0, 8)} - ${order.status}`,
          amount: order.total_price || 0,
          customer: order.users?.full_name || order.users?.email || 'Unknown',
          timestamp: order.created_at
        }));
      },
      15 // 15 second cache for activity
    );

    res.json({
      success: true,
      data,
      _meta: { cached: fromCache }
    });
  } catch (error) {
    logger.error('Error fetching activity', { error: error.message });
    next(error);
  }
});

export default router;
