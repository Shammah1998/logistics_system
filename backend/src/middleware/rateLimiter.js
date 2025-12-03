import rateLimit from 'express-rate-limit';

// More lenient rate limiting for development/testing
// In production, you may want stricter limits
const rateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'production' ? 100 : 1000, // Higher limit for development
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Skip rate limiting for localhost and health checks in development
  skip: (req) => {
    // Always skip health checks
    if (req.path === '/health' || req.path === '/') {
      return true;
    }
    
    // Skip for localhost in development
    if (process.env.NODE_ENV !== 'production') {
      const ip = req.ip || req.connection.remoteAddress || req.headers['x-forwarded-for']?.split(',')[0]?.trim();
      return ip === '127.0.0.1' || ip === '::1' || ip === '::ffff:127.0.0.1' || ip?.includes('localhost') || !ip;
    }
    return false;
  },
});

export default rateLimiter;

