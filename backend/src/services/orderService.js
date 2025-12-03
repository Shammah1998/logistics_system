import orderRepository from '../repositories/orderRepository.js';
import { calculateOrderPrice } from './pricingService.js';
import { supabase } from '../server.js';
import { logger } from '../utils/logger.js';

export class OrderService {
  /**
   * Create a new order
   * @param {Object} orderData - Order data from request
   * @param {string} customerId - Customer user ID
   * @returns {Promise<Object>} Created order
   */
  async createOrder(orderData, customerId) {
    try {
      // Validate multi-drop limits
      const isCorporate = orderData.company_id !== null;
      const dropCount = orderData.drops?.length || 0;

      if (!isCorporate && dropCount > 4) {
        throw new Error('Retail customers can have maximum 4 drops');
      }

      // Calculate pricing
      const pricing = await calculateOrderPrice(
        orderData,
        orderData.company_id,
        orderData.vehicle_type,
        orderData.pricing_mode
      );

      // Generate order number
      const { data: orderNumberData, error: orderNumError } = await supabase
        .rpc('generate_order_number');

      if (orderNumError) {
        throw new Error(`Failed to generate order number: ${orderNumError.message}`);
      }

      const orderNumber = orderNumberData || `ORD-${new Date().getFullYear()}-${Date.now().toString().slice(-6)}`;

      // Prepare order data
      const orderRecord = {
        order_number: orderNumber,
        customer_id: customerId,
        company_id: orderData.company_id || null,
        vehicle_type: orderData.vehicle_type,
        pricing_mode: orderData.pricing_mode,
        pickup_address: orderData.pickup_address,
        total_distance_km: pricing.total_distance_km,
        base_price: pricing.base_price,
        total_price: pricing.total_price,
        status: 'pending',
        payment_status: 'pending',
        payment_method: orderData.payment_method || null,
        scheduled_pickup_time: orderData.scheduled_pickup_time || null
      };

      // Create order
      const order = await orderRepository.create(orderRecord);

      // Create order items if provided
      if (orderData.items && orderData.items.length > 0) {
        const items = orderData.items.map(item => ({
          order_id: order.id,
          description: item.description,
          quantity: item.quantity,
          unit_price: item.unit_price,
          total_price: item.quantity * item.unit_price
        }));

        await orderRepository.createOrderItems(items);
      }

      // Create drops
      if (orderData.drops && orderData.drops.length > 0) {
        const drops = orderData.drops.map((drop, index) => ({
          order_id: order.id,
          drop_sequence: index + 1,
          recipient_name: drop.recipient_name,
          recipient_phone: drop.recipient_phone,
          address: drop.address,
          delivery_instructions: drop.delivery_instructions || null,
          status: 'pending'
        }));

        await orderRepository.createDrops(drops);
      }

      // Log audit
      await this.logAudit(customerId, 'order_created', 'orders', order.id, {
        order_number: order.order_number,
        total_price: order.total_price
      });

      logger.info('Order created successfully', {
        order_id: order.id,
        order_number: order.order_number,
        customer_id: customerId
      });

      return await orderRepository.findByIdWithRelations(order.id);
    } catch (error) {
      logger.error('Failed to create order', {
        error: error.message,
        customer_id: customerId
      });
      throw error;
    }
  }

  /**
   * Get order by ID
   * @param {string} orderId - Order ID
   * @returns {Promise<Object>} Order data
   */
  async getOrderById(orderId) {
    try {
      return await orderRepository.findByIdWithRelations(orderId);
    } catch (error) {
      logger.error('Failed to get order', {
        error: error.message,
        order_id: orderId
      });
      throw error;
    }
  }

  /**
   * Log audit event
   * @param {string} userId - User ID
   * @param {string} action - Action name
   * @param {string} entityType - Entity type
   * @param {string} entityId - Entity ID
   * @param {Object} changes - Changes object
   */
  async logAudit(userId, action, entityType, entityId, changes = {}) {
    try {
      await supabase.from('audit_logs').insert({
        user_id: userId,
        action,
        entity_type: entityType,
        entity_id: entityId,
        changes
      });
    } catch (error) {
      logger.error('Failed to log audit', { error: error.message });
      // Don't throw - audit logging failure shouldn't break the flow
    }
  }
}

export default new OrderService();

