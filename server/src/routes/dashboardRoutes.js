import express from 'express';
import { authenticate, requireUserType } from '../middleware/auth.js';
import { supabase } from '../server.js';
import { logger } from '../utils/logger.js';
import { cache, CacheTTL, CacheKeys } from '../services/cacheService.js';

const router = express.Router();

// Helper function to fetch dashboard stats from database
async function fetchDashboardStats() {
  // Run queries in parallel for better performance
  const [
    ordersResult,
    ordersByStatusResult,
    activeDriversResult,
    totalDriversResult,
    totalCustomersResult,
    revenueResult,
    pendingPODsResult,
    todayOrdersResult,
    monthlyRevenueResult
  ] = await Promise.all([
    // Total orders
    supabase.from('orders').select('*', { count: 'exact', head: true }),
    // Orders by status
    supabase.from('orders').select('status'),
    // Active drivers
    supabase.from('drivers').select('*', { count: 'exact', head: true }).eq('status', 'active'),
    // Total drivers
    supabase.from('drivers').select('*', { count: 'exact', head: true }),
    // Total customers
    supabase.from('users').select('*', { count: 'exact', head: true }).eq('user_type', 'customer'),
    // Revenue (delivered orders)
    supabase.from('orders').select('total_amount').eq('status', 'delivered'),
    // Pending PODs
    supabase.from('proof_of_delivery').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
    // Today's orders
    supabase.from('orders').select('*', { count: 'exact', head: true }).gte('created_at', new Date(new Date().setHours(0, 0, 0, 0)).toISOString()),
    // Monthly revenue
    supabase.from('orders').select('total_amount').eq('status', 'delivered').gte('created_at', new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString())
  ]);

  // Process status counts
  const statusCounts = {
    pending: 0,
    assigned: 0,
    in_transit: 0,
    delivered: 0,
    cancelled: 0
  };

  if (ordersByStatusResult.data) {
    ordersByStatusResult.data.forEach(order => {
      if (statusCounts.hasOwnProperty(order.status)) {
        statusCounts[order.status]++;
      }
    });
  }

  // Calculate totals
  const totalRevenue = revenueResult.data?.reduce((sum, order) => sum + (order.total_amount || 0), 0) || 0;
  const monthlyRevenue = monthlyRevenueResult.data?.reduce((sum, order) => sum + (order.total_amount || 0), 0) || 0;

  return {
    orders: {
      total: ordersResult.count || 0,
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
            total_amount,
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
          amount: order.total_amount,
          customer: order.users?.full_name || 'Unknown',
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
