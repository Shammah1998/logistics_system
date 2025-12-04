import express from 'express';
import { authenticate, requireUserType } from '../middleware/auth.js';
import { cache, CacheKeys } from '../services/cacheService.js';
import { logger } from '../utils/logger.js';

const router = express.Router();

// All admin routes require authentication and admin role
router.use(authenticate);
router.use(requireUserType('admin'));

// ============================================
// CACHE MANAGEMENT ENDPOINTS
// ============================================

// Get cache status
router.get('/cache/status', async (req, res) => {
  res.json({
    success: true,
    data: {
      connected: cache.isAvailable(),
      message: cache.isAvailable() ? 'Redis cache is connected and operational' : 'Cache is not available (running without cache)'
    }
  });
});

// Clear all caches
router.post('/cache/clear', async (req, res) => {
  try {
    if (!cache.isAvailable()) {
      return res.json({
        success: true,
        message: 'Cache is not available, nothing to clear'
      });
    }

    await Promise.all([
      cache.invalidateEntity(CacheKeys.DASHBOARD),
      cache.invalidateEntity(CacheKeys.ORDERS),
      cache.invalidateEntity(CacheKeys.DRIVERS),
      cache.invalidateEntity(CacheKeys.CUSTOMERS),
      cache.invalidateEntity(CacheKeys.USER),
      cache.invalidateEntity(CacheKeys.WALLET)
    ]);

    logger.info('All caches cleared by admin', { adminId: req.user.id });

    res.json({
      success: true,
      message: 'All caches cleared successfully'
    });
  } catch (error) {
    logger.error('Error clearing cache', { error: error.message });
    res.status(500).json({
      success: false,
      message: 'Failed to clear cache'
    });
  }
});

// Clear specific cache entity
router.post('/cache/clear/:entity', async (req, res) => {
  try {
    const { entity } = req.params;
    const validEntities = Object.values(CacheKeys);

    if (!validEntities.includes(entity)) {
      return res.status(400).json({
        success: false,
        message: `Invalid entity. Valid options: ${validEntities.join(', ')}`
      });
    }

    if (!cache.isAvailable()) {
      return res.json({
        success: true,
        message: 'Cache is not available, nothing to clear'
      });
    }

    await cache.invalidateEntity(entity);

    logger.info(`Cache cleared for entity: ${entity}`, { adminId: req.user.id });

    res.json({
      success: true,
      message: `Cache cleared for ${entity}`
    });
  } catch (error) {
    logger.error('Error clearing cache', { error: error.message });
    res.status(500).json({
      success: false,
      message: 'Failed to clear cache'
    });
  }
});

// ============================================
// SYSTEM HEALTH ENDPOINTS
// ============================================

// Get system health
router.get('/health', async (req, res) => {
  const health = {
    server: 'healthy',
    cache: cache.isAvailable() ? 'connected' : 'disconnected',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage()
  };

  res.json({
    success: true,
    data: health
  });
});

export default router;

