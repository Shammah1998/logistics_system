import express from 'express';
import { authenticate, requireUserType } from '../middleware/auth.js';
import { createOrder, getOrderById, validateCreateOrder } from '../controllers/orderController.js';
import { supabase } from '../server.js';
import { logger } from '../utils/logger.js';
import { cache, CacheTTL, CacheKeys } from '../services/cacheService.js';

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// Helper function to fetch and format orders
async function fetchOrders(userId, userType, status, limit, offset) {
  // Use both total_distance and total_distance_km for compatibility
  let query = supabase
    .from('orders')
    .select(`
      id,
      order_number,
      pickup_address,
      total_price,
      total_distance,
      total_distance_km,
      status,
      vehicle_type,
      created_at,
      customer_id,
      driver_id,
      users!customer_id (
        id,
        full_name,
        phone,
        email
      ),
      drops (
        id,
        recipient_name,
        address,
        recipient_phone,
        status,
        drop_sequence
      )
    `)
    .order('created_at', { ascending: false })
    .range(parseInt(offset), parseInt(offset) + parseInt(limit) - 1);

  // Filter by user type
  if (userType === 'customer') {
    query = query.eq('customer_id', userId);
  } else if (userType === 'driver') {
    query = query.eq('driver_id', userId);
  }

  // Filter by status if provided
  if (status) {
    query = query.eq('status', status);
  }

  const { data: orders, error } = await query;

  if (error) {
    logger.error('Error fetching orders from database', { 
      error: error.message, 
      code: error.code,
      details: error.details,
      hint: error.hint
    });
    throw error;
  }

  // Get driver info for orders with drivers assigned
  const driverIds = [...new Set(orders?.filter(o => o.driver_id).map(o => o.driver_id) || [])];
  let driversMap = {};
  
  if (driverIds.length > 0) {
    const { data: drivers } = await supabase
      .from('users')
      .select('id, full_name, phone')
      .in('id', driverIds);
    
    if (drivers) {
      drivers.forEach(d => {
        driversMap[d.id] = d;
      });
    }
  }

  // Format response - handle missing columns gracefully
  return (orders || []).map(order => ({
    id: order.id,
    orderNumber: order.order_number || order.id.slice(0, 8).toUpperCase(),
    pickupAddress: order.pickup_address,
    totalAmount: order.total_price || 0,
    totalDistance: order.total_distance || order.total_distance_km || 0,
    status: order.status,
    vehicleType: order.vehicle_type,
    createdAt: order.created_at,
    customer: order.users ? {
      id: order.customer_id,
      name: order.users.full_name || order.users.email || 'Unknown',
      phone: order.users.phone || '',
      email: order.users.email || ''
    } : null,
    driver: order.driver_id && driversMap[order.driver_id] ? {
      id: order.driver_id,
      name: driversMap[order.driver_id].full_name || driversMap[order.driver_id].email || 'Unknown',
      phone: driversMap[order.driver_id].phone || ''
    } : null,
    drops: (order.drops || []).sort((a, b) => (a.drop_sequence || a.sequence_number || 0) - (b.drop_sequence || b.sequence_number || 0)).map(drop => ({
      id: drop.id,
      recipientName: drop.recipient_name || '',
      address: drop.address || '',
      phone: drop.recipient_phone || drop.phone || '',
      status: drop.status
    })),
    dropCount: order.drops?.length || 0
  }));
}

// Get all orders - admin sees all, customers see their own (CACHED)
router.get('/', async (req, res, next) => {
  try {
    // Validate and sanitize pagination parameters
    const maxLimit = 100; // Maximum records per page
    const defaultLimit = 50;
    const limit = Math.min(Math.max(parseInt(req.query.limit) || defaultLimit, 1), maxLimit);
    const offset = Math.max(parseInt(req.query.offset) || 0, 0);
    const status = req.query.status;
    
    const userId = req.user.id;
    const userType = req.user.user_type;

    // Generate cache key based on user type and filters
    const cacheKey = cache.generateKey(
      CacheKeys.ORDERS,
      userType,
      userType === 'admin' ? 'all' : userId,
      status || 'all',
      limit,
      offset
    );

    const { data: formattedOrders, fromCache } = await cache.getOrSet(
      cacheKey,
      () => fetchOrders(userId, userType, status, limit, offset),
      CacheTTL.ORDERS_LIST
    );

    res.json({
      success: true,
      data: formattedOrders,
      pagination: {
        limit,
        offset,
        total: formattedOrders.length,
        hasMore: formattedOrders.length === limit // Indicates if more records exist
      },
      _meta: { cached: fromCache }
    });
  } catch (error) {
    logger.error('Error in get orders', { error: error.message });
    next(error);
  }
});

// Get customer's own orders (alias for customers) - CACHED
router.get('/my/orders', async (req, res, next) => {
  try {
    const userId = req.user.id;
    // Validate and sanitize limit
    const maxLimit = 100;
    const defaultLimit = 50;
    const limit = Math.min(Math.max(parseInt(req.query.limit) || defaultLimit, 1), maxLimit);
    const status = req.query.status;

    const cacheKey = cache.generateKey(CacheKeys.ORDERS, 'my', userId, status || 'all', limit);

    const { data: orders, fromCache } = await cache.getOrSet(
      cacheKey,
      async () => {
        let query = supabase
          .from('orders')
          .select(`
            id,
            order_number,
            pickup_address,
            total_price,
            total_distance,
            total_distance_km,
            status,
            vehicle_type,
            created_at,
            driver_id,
            drops (
              id,
              recipient_name,
              address,
              recipient_phone,
              status,
              drop_sequence
            )
          `)
          .eq('customer_id', userId)
          .order('created_at', { ascending: false })
          .limit(parseInt(limit));

        if (status) {
          query = query.eq('status', status);
        }

        const { data, error } = await query;
        if (error) throw error;
        return data || [];
      },
      CacheTTL.ORDERS_LIST
    );

    res.json({
      success: true,
      data: orders,
      _meta: { cached: fromCache }
    });
  } catch (error) {
    logger.error('Error in get my orders', { error: error.message });
    next(error);
  }
});

// Create order - customers only (INVALIDATES CACHE)
router.post(
  '/create',
  requireUserType('customer', 'admin'),
  validateCreateOrder,
  async (req, res, next) => {
    try {
      // Create the order using the controller
      await createOrder(req, res, next);
      
      // Invalidate orders cache after successful creation
      await cache.invalidateEntity(CacheKeys.ORDERS);
      await cache.invalidateEntity(CacheKeys.DASHBOARD);
    } catch (error) {
      next(error);
    }
  }
);

// Get order by ID - customers, drivers, and admins (CACHED)
router.get('/:orderId', async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const cacheKey = cache.generateKey(CacheKeys.ORDERS, 'detail', orderId);

    const { data, fromCache } = await cache.getOrSet(
      cacheKey,
      async () => {
        // Call the existing controller but capture the response
        return new Promise((resolve, reject) => {
          const mockRes = {
            json: (data) => resolve(data),
            status: () => ({ json: (data) => reject(new Error(data.message || 'Error')) })
          };
          getOrderById({ ...req, params: { orderId } }, mockRes, reject);
        });
      },
      CacheTTL.ORDER_DETAIL
    );

    if (data.success === false) {
      return res.status(404).json(data);
    }

    res.json({ ...data, _meta: { cached: fromCache } });
  } catch (error) {
    logger.error('Error in get order by ID', { error: error.message });
    next(error);
  }
});

// Update order status - admin and drivers (INVALIDATES CACHE)
router.patch('/:orderId/status', requireUserType('admin', 'driver'), async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;

    const validStatuses = ['pending', 'assigned', 'in_transit', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`
      });
    }

    const { data, error } = await supabase
      .from('orders')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', orderId)
      .select()
      .single();

    if (error) {
      logger.error('Error updating order status', { error: error.message });
      return res.status(500).json({
        success: false,
        message: 'Failed to update order status'
      });
    }

    // Invalidate caches
    await Promise.all([
      cache.del(cache.generateKey(CacheKeys.ORDERS, 'detail', orderId)),
      cache.invalidateEntity(CacheKeys.ORDERS),
      cache.invalidateEntity(CacheKeys.DASHBOARD)
    ]);

    res.json({
      success: true,
      message: 'Order status updated',
      data
    });
  } catch (error) {
    logger.error('Error in update order status', { error: error.message });
    next(error);
  }
});

// Assign driver to order - admin only (INVALIDATES CACHE)
router.patch('/:orderId/assign', requireUserType('admin'), async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const { driverId } = req.body;

    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: 'Driver ID is required'
      });
    }

    // Verify driver exists and is active
    const { data: driver, error: driverError } = await supabase
      .from('drivers')
      .select('id, status')
      .eq('id', driverId)
      .single();

    if (driverError || !driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    if (driver.status !== 'active') {
      return res.status(400).json({
        success: false,
        message: 'Driver is not active'
      });
    }

    const { data, error } = await supabase
      .from('orders')
      .update({ 
        driver_id: driverId, 
        status: 'assigned',
        updated_at: new Date().toISOString() 
      })
      .eq('id', orderId)
      .select()
      .single();

    if (error) {
      logger.error('Error assigning driver', { error: error.message });
      return res.status(500).json({
        success: false,
        message: 'Failed to assign driver'
      });
    }

    // Invalidate caches
    await Promise.all([
      cache.del(cache.generateKey(CacheKeys.ORDERS, 'detail', orderId)),
      cache.invalidateEntity(CacheKeys.ORDERS),
      cache.invalidateEntity(CacheKeys.DASHBOARD)
    ]);

    res.json({
      success: true,
      message: 'Driver assigned successfully',
      data
    });
  } catch (error) {
    logger.error('Error in assign driver', { error: error.message });
    next(error);
  }
});

export default router;
