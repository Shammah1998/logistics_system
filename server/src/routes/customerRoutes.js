import express from 'express';
import { authenticate, requireUserType } from '../middleware/auth.js';
import { supabase } from '../server.js';
import { logger } from '../utils/logger.js';
import { cache, CacheTTL, CacheKeys } from '../services/cacheService.js';

const router = express.Router();

// Helper function to fetch customers with stats
async function fetchCustomersWithStats() {
  const { data: customers, error } = await supabase
    .from('users')
    .select(`
      id,
      email,
      phone,
      full_name,
      user_type,
      created_at
    `)
    .eq('user_type', 'customer')
    .order('created_at', { ascending: false });

  if (error) {
    logger.error('Error fetching customers from database', { 
      error: error.message, 
      code: error.code,
      details: error.details,
      hint: error.hint
    });
    throw error;
  }

  // Get order stats for all customers in parallel
  const customerIds = customers.map(c => c.id);
  
  const { data: orderStats } = await supabase
    .from('orders')
    .select('customer_id, total_price, status')
    .in('customer_id', customerIds);

  // Calculate stats per customer
  const statsMap = {};
  if (orderStats) {
    orderStats.forEach(order => {
      if (!statsMap[order.customer_id]) {
        statsMap[order.customer_id] = {
          orderCount: 0,
          totalSpent: 0,
          pendingOrders: 0
        };
      }
      statsMap[order.customer_id].orderCount++;
      statsMap[order.customer_id].totalSpent += order.total_price || 0;
      if (['pending', 'assigned', 'in_transit'].includes(order.status)) {
        statsMap[order.customer_id].pendingOrders++;
      }
    });
  }

  // Format response - handle missing columns gracefully
  return customers.map(customer => ({
    id: customer.id,
    name: customer.full_name || customer.email || 'Unknown',
    email: customer.email || '',
    phone: customer.phone || '',
    orderCount: statsMap[customer.id]?.orderCount || 0,
    totalSpent: statsMap[customer.id]?.totalSpent || 0,
    pendingOrders: statsMap[customer.id]?.pendingOrders || 0,
    status: 'active',
    createdAt: customer.created_at
  }));
}

// Get all customers - admins only (CACHED)
router.get('/', authenticate, requireUserType('admin'), async (req, res, next) => {
  try {
    const cacheKey = cache.generateKey(CacheKeys.CUSTOMERS, 'list');

    const { data: formattedCustomers, fromCache } = await cache.getOrSet(
      cacheKey,
      fetchCustomersWithStats,
      CacheTTL.CUSTOMERS_LIST
    );

    res.json({
      success: true,
      data: formattedCustomers,
      _meta: { cached: fromCache }
    });
  } catch (error) {
    logger.error('Error in get customers', { error: error.message });
    next(error);
  }
});

// Get customer by ID - admins only (CACHED)
router.get('/:customerId', authenticate, requireUserType('admin'), async (req, res, next) => {
  try {
    const { customerId } = req.params;
    const cacheKey = cache.generateKey(CacheKeys.CUSTOMERS, 'detail', customerId);

    const { data, fromCache } = await cache.getOrSet(
      cacheKey,
      async () => {
        const { data: customer, error } = await supabase
          .from('users')
          .select('id, email, phone, full_name, created_at')
          .eq('id', customerId)
          .eq('user_type', 'customer')
          .single();

        if (error || !customer) {
          throw new Error('Customer not found');
        }

        // Get customer's recent orders
        const { data: orders } = await supabase
          .from('orders')
          .select('id, total_price, status, created_at')
          .eq('customer_id', customerId)
          .order('created_at', { ascending: false })
          .limit(10);

        return {
          ...customer,
          recentOrders: orders || []
        };
      },
      CacheTTL.USER_PROFILE
    );

    res.json({
      success: true,
      data,
      _meta: { cached: fromCache }
    });
  } catch (error) {
    if (error.message === 'Customer not found') {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }
    logger.error('Error fetching customer', { error: error.message });
    next(error);
  }
});

export default router;
