import { createClient } from 'redis';
import { logger } from '../utils/logger.js';

class CacheService {
  constructor() {
    this.client = null;
    this.isConnected = false;
    this.defaultTTL = 60; // 60 seconds default
  }

  // Initialize Redis connection
  async connect() {
    try {
      // Check if using individual Redis config vars (recommended for Redis Cloud)
      const redisHost = process.env.REDIS_HOST;
      const redisPort = process.env.REDIS_PORT;
      const redisPassword = process.env.REDIS_PASSWORD;
      const redisUrl = process.env.REDIS_URL;
      
      let clientConfig;
      
      if (redisHost && redisPort && redisPassword) {
        // Use separate config (Redis Cloud recommended format)
        logger.info('Connecting to Redis using host/port config...');
        const isProduction = process.env.NODE_ENV === 'production';
        clientConfig = {
          username: 'default',
          password: redisPassword,
          socket: {
            host: redisHost,
            port: parseInt(redisPort),
            // Redis Cloud requires TLS in production
            tls: isProduction ? true : undefined,
            reconnectStrategy: (retries) => {
              if (retries > 10) {
                logger.warn('Redis: Max reconnection attempts reached, running without cache');
                return false;
              }
              return Math.min(retries * 100, 3000);
            }
          }
        };
      } else if (redisUrl) {
        // Use URL format (fallback)
        logger.info('Connecting to Redis using URL config...');
        const isSSL = redisUrl.startsWith('rediss://');
        clientConfig = {
          url: redisUrl,
          socket: {
            tls: isSSL,
            reconnectStrategy: (retries) => {
              if (retries > 10) {
                logger.warn('Redis: Max reconnection attempts reached, running without cache');
                return false;
              }
              return Math.min(retries * 100, 3000);
            }
          }
        };
      } else {
        // Local development default
        logger.info('No Redis config found, using localhost...');
        clientConfig = {
          url: 'redis://localhost:6379',
          socket: {
            reconnectStrategy: (retries) => {
              if (retries > 3) {
                logger.warn('Redis: Local Redis not available, running without cache');
                return false;
              }
              return Math.min(retries * 100, 1000);
            }
          }
        };
      }
      
      this.client = createClient(clientConfig);

      this.client.on('error', (err) => {
        logger.error('Redis Client Error:', { message: err.message, stack: err.stack });
        this.isConnected = false;
      });

      this.client.on('connect', () => {
        logger.info('Redis connected successfully');
        this.isConnected = true;
      });

      this.client.on('reconnecting', () => {
        logger.info('Redis reconnecting...');
      });

      await this.client.connect();
      this.isConnected = true;
      logger.info('✅ Redis cache initialized');
      return true;
    } catch (error) {
      logger.warn('⚠️ Redis connection failed, running without cache:', { 
        message: error.message, 
        code: error.code
      });
      this.isConnected = false;
      return false;
    }
  }

  // Check if cache is available
  isAvailable() {
    return this.isConnected && this.client;
  }

  // Generate cache key with prefix
  generateKey(prefix, ...parts) {
    return `logistics:${prefix}:${parts.join(':')}`;
  }

  // Get cached data
  async get(key) {
    if (!this.isAvailable()) return null;
    
    try {
      const data = await this.client.get(key);
      if (data) {
        logger.info(`✅ Cache HIT: ${key}`);
        return JSON.parse(data);
      }
      logger.info(`❌ Cache MISS: ${key}`);
      return null;
    } catch (error) {
      logger.error('Cache get error:', error.message);
      return null;
    }
  }

  // Set cached data with TTL
  async set(key, data, ttl = this.defaultTTL) {
    if (!this.isAvailable()) return false;
    
    try {
      await this.client.setEx(key, ttl, JSON.stringify(data));
      logger.info(`💾 Cache SET: ${key} (TTL: ${ttl}s)`);
      return true;
    } catch (error) {
      logger.error('Cache set error:', error.message);
      return false;
    }
  }

  // Delete specific key
  async del(key) {
    if (!this.isAvailable()) return false;
    
    try {
      await this.client.del(key);
      logger.info(`🗑️ Cache DEL: ${key}`);
      return true;
    } catch (error) {
      logger.error('Cache del error:', error.message);
      return false;
    }
  }

  // Delete keys by pattern
  async delByPattern(pattern) {
    if (!this.isAvailable()) return false;
    
    try {
      const keys = await this.client.keys(pattern);
      if (keys.length > 0) {
        await this.client.del(keys);
        logger.info(`🗑️ Cache DEL pattern: ${pattern} (${keys.length} keys)`);
      }
      return true;
    } catch (error) {
      logger.error('Cache delByPattern error:', error.message);
      return false;
    }
  }

  // Invalidate all caches for a specific entity
  async invalidateEntity(entity) {
    return this.delByPattern(`logistics:${entity}:*`);
  }

  // Cache wrapper - get or fetch
  async getOrSet(key, fetchFunction, ttl = this.defaultTTL) {
    // Try to get from cache first
    const cached = await this.get(key);
    if (cached !== null) {
      return { data: cached, fromCache: true };
    }

    // Fetch fresh data
    const freshData = await fetchFunction();
    
    // Store in cache (don't await to avoid blocking)
    this.set(key, freshData, ttl).catch(() => {});
    
    return { data: freshData, fromCache: false };
  }

  // Disconnect
  async disconnect() {
    if (this.client) {
      await this.client.quit();
      this.isConnected = false;
      logger.info('Redis disconnected');
    }
  }
}

// Cache TTL configurations (in seconds)
export const CacheTTL = {
  DASHBOARD_STATS: 30,      // Dashboard refreshes often
  ORDERS_LIST: 15,          // Orders change frequently
  DRIVERS_LIST: 60,         // Drivers change less often
  CUSTOMERS_LIST: 120,      // Customers change rarely
  USER_PROFILE: 300,        // Profile changes rarely
  ORDER_DETAIL: 30,         // Order details need to be current
  WALLET: 60,               // Wallet balance
};

// Cache key prefixes
export const CacheKeys = {
  DASHBOARD: 'dashboard',
  ORDERS: 'orders',
  DRIVERS: 'drivers',
  CUSTOMERS: 'customers',
  USER: 'user',
  WALLET: 'wallet',
};

// Export singleton instance
export const cache = new CacheService();
export default cache;

