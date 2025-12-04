// Load environment variables FIRST, before any other imports
import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createClient } from '@supabase/supabase-js';
import orderRoutes from './routes/orderRoutes.js';
import driverRoutes from './routes/driverRoutes.js';
import podRoutes from './routes/podRoutes.js';
import authRoutes from './routes/authRoutes.js';
import { errorHandler } from './middleware/errorHandler.js';
import { logger } from './utils/logger.js';
import rateLimiter from './middleware/rateLimiter.js';

// Validate required environment variables
const requiredEnvVars = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
const missingEnvVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingEnvVars.length > 0) {
  console.error('❌ Missing required environment variables:');
  missingEnvVars.forEach(varName => {
    console.error(`   - ${varName}`);
  });
  console.error('\nPlease create a .env file in the backend directory with all required variables.');
  console.error('See .env.example for reference.');
  process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

export const supabase = createClient(supabaseUrl, supabaseKey);

// Middleware
app.use(helmet());

// CORS configuration - allow multiple origins for development and production
const allowedOrigins = [
  // Development origins
  'http://localhost:3001',  // Customer panel dev
  'http://localhost:3002',  // Admin panel dev
  'http://localhost:5173',  // Vite default
  'http://127.0.0.1:3001',
  'http://127.0.0.1:3002',
  'http://127.0.0.1:5173',
  // Production origins (set via environment variables)
  process.env.CUSTOMER_PANEL_URL,  // Vercel customer panel URL
  process.env.ADMIN_PANEL_URL,     // Vercel admin panel URL
  process.env.FRONTEND_URL         // Legacy - backwards compatibility
].filter(Boolean);

app.use(cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (like mobile apps, Postman, or server-to-server)
    if (!origin) {
      return callback(null, true);
    }
    
    // Allow all localhost origins in development
    if (process.env.NODE_ENV !== 'production' && origin.includes('localhost')) {
      return callback(null, true);
    }
    
    // Allow Vercel preview and production URLs (*.vercel.app)
    if (origin.endsWith('.vercel.app')) {
      return callback(null, true);
    }
    
    // Check against allowed origins
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    // Log blocked origins for debugging
    console.log('CORS blocked origin:', origin);
    return callback(new Error('Not allowed by CORS'), false);
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint (before rate limiting)
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Root endpoint - API information (before rate limiting)
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Logistics Platform API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      orders: '/api/orders',
      drivers: '/api/drivers',
      pods: '/api/pods'
    },
    documentation: '/api/docs'
  });
});

// Rate limiting (applied after health check routes)
app.use(rateLimiter);

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// API info endpoint
app.get('/api', (req, res) => {
  res.json({
    success: true,
    message: 'Logistics Platform API',
    version: '1.0.0',
    availableEndpoints: {
      auth: {
        driverLogin: 'POST /api/auth/drivers/login',
        verifyToken: 'GET /api/auth/verify',
        logout: 'POST /api/auth/logout'
      },
      orders: {
        create: 'POST /api/orders/create',
        getById: 'GET /api/orders/:orderId'
      },
      drivers: {
        assignOrder: 'POST /api/drivers/:driverId/assign-order'
      },
      pods: {
        upload: 'POST /api/pods/upload',
        approve: 'POST /api/pods/:podId/approve'
      }
    },
    documentation: 'See API_DOCUMENTATION.md for details'
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/drivers', driverRoutes);
app.use('/api/pods', podRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Error handler (must be last)
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`, {
    env: process.env.NODE_ENV,
    port: PORT
  });
});

export default app;

