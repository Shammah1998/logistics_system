import express from 'express';
import { authenticate, requireUserType } from '../middleware/auth.js';
import { createOrder, getOrderById, validateCreateOrder } from '../controllers/orderController.js';

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// Create order - customers only
router.post(
  '/create',
  requireUserType('customer', 'admin'),
  validateCreateOrder,
  createOrder
);

// Get order by ID - customers, drivers, and admins
router.get('/:orderId', getOrderById);

export default router;

