import { body, validationResult } from 'express-validator';
import orderService from '../services/orderService.js';
import { logger } from '../utils/logger.js';

/**
 * Validation rules for order creation
 */
export const validateCreateOrder = [
  body('vehicle_type')
    .isIn(['small', 'medium', 'large'])
    .withMessage('Vehicle type must be small, medium, or large'),
  body('pricing_mode')
    .isIn(['distance_based', 'per_box'])
    .withMessage('Pricing mode must be distance_based or per_box'),
  body('pickup_address')
    .isObject()
    .withMessage('Pickup address is required'),
  body('pickup_address.coordinates.lat')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Invalid latitude'),
  body('pickup_address.coordinates.lng')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Invalid longitude'),
  body('drops')
    .isArray({ min: 1 })
    .withMessage('At least one drop location is required'),
  body('drops.*.recipient_name')
    .notEmpty()
    .withMessage('Recipient name is required for each drop'),
  body('drops.*.recipient_phone')
    .notEmpty()
    .withMessage('Recipient phone is required for each drop'),
  body('drops.*.address.coordinates.lat')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Invalid drop latitude'),
  body('drops.*.address.coordinates.lng')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Invalid drop longitude'),
  body('items')
    .if(body('pricing_mode').equals('per_box'))
    .isArray({ min: 1 })
    .withMessage('Items are required for per_box pricing mode'),
  body('items.*.description')
    .if(body('pricing_mode').equals('per_box'))
    .notEmpty()
    .withMessage('Item description is required'),
  body('items.*.quantity')
    .if(body('pricing_mode').equals('per_box'))
    .isInt({ min: 1 })
    .withMessage('Item quantity must be at least 1'),
  body('items.*.unit_price')
    .if(body('pricing_mode').equals('per_box'))
    .isFloat({ min: 0 })
    .withMessage('Item unit price must be positive')
];

/**
 * Create a new order
 */
export const createOrder = async (req, res, next) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const customerId = req.user.id;
    const orderData = req.body;

    const order = await orderService.createOrder(orderData, customerId);

    res.status(201).json({
      success: true,
      data: {
        order_id: order.id,
        order_number: order.order_number,
        total_distance_km: order.total_distance_km,
        base_price: order.base_price,
        total_price: order.total_price,
        payment_status: order.payment_status,
        status: order.status
      }
    });
  } catch (error) {
    logger.error('Order creation failed', {
      error: error.message,
      customer_id: req.user?.id
    });
    next(error);
  }
};

/**
 * Get order by ID
 */
export const getOrderById = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const order = await orderService.getOrderById(orderId);

    res.json({
      success: true,
      data: order
    });
  } catch (error) {
    logger.error('Failed to get order', {
      error: error.message,
      order_id: req.params.orderId
    });
    next(error);
  }
};

