import { supabase } from '../server.js';

export class OrderRepository {
  /**
   * Create a new order
   * @param {Object} orderData - Order data
   * @returns {Promise<Object>} Created order
   */
  async create(orderData) {
    const { data, error } = await supabase
      .from('orders')
      .insert(orderData)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create order: ${error.message}`);
    }

    return data;
  }

  /**
   * Find order by ID
   * @param {string} orderId - Order ID
   * @returns {Promise<Object>} Order data
   */
  async findById(orderId) {
    const { data, error } = await supabase
      .from('orders')
      .select(`
        *,
        customer:users!orders_customer_id_fkey(id, email, phone),
        company:companies(id, name, client_type),
        driver:drivers!orders_driver_id_fkey(
          id,
          license_number,
          vehicle_type,
          user:users!drivers_id_fkey(id, email, phone)
        )
      `)
      .eq('id', orderId)
      .single();

    if (error) {
      throw new Error(`Failed to find order: ${error.message}`);
    }

    return data;
  }

  /**
   * Find order by order number
   * @param {string} orderNumber - Order number
   * @returns {Promise<Object>} Order data
   */
  async findByOrderNumber(orderNumber) {
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('order_number', orderNumber)
      .single();

    if (error) {
      throw new Error(`Failed to find order: ${error.message}`);
    }

    return data;
  }

  /**
   * Update order
   * @param {string} orderId - Order ID
   * @param {Object} updates - Fields to update
   * @returns {Promise<Object>} Updated order
   */
  async update(orderId, updates) {
    const { data, error } = await supabase
      .from('orders')
      .update(updates)
      .eq('id', orderId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update order: ${error.message}`);
    }

    return data;
  }

  /**
   * Create order items
   * @param {Array} items - Array of order items
   * @returns {Promise<Array>} Created items
   */
  async createOrderItems(items) {
    const { data, error } = await supabase
      .from('order_items')
      .insert(items)
      .select();

    if (error) {
      throw new Error(`Failed to create order items: ${error.message}`);
    }

    return data;
  }

  /**
   * Create drops
   * @param {Array} drops - Array of drop locations
   * @returns {Promise<Array>} Created drops
   */
  async createDrops(drops) {
    const { data, error } = await supabase
      .from('drops')
      .insert(drops)
      .select();

    if (error) {
      throw new Error(`Failed to create drops: ${error.message}`);
    }

    return data;
  }

  /**
   * Get order with all related data
   * @param {string} orderId - Order ID
   * @returns {Promise<Object>} Complete order data
   */
  async findByIdWithRelations(orderId) {
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('*')
      .eq('id', orderId)
      .single();

    if (orderError) {
      throw new Error(`Failed to find order: ${orderError.message}`);
    }

    // Get order items
    const { data: items, error: itemsError } = await supabase
      .from('order_items')
      .select('*')
      .eq('order_id', orderId)
      .order('created_at');

    if (itemsError) {
      throw new Error(`Failed to fetch order items: ${itemsError.message}`);
    }

    // Get drops
    const { data: drops, error: dropsError } = await supabase
      .from('drops')
      .select('*')
      .eq('order_id', orderId)
      .order('drop_sequence');

    if (dropsError) {
      throw new Error(`Failed to fetch drops: ${dropsError.message}`);
    }

    return {
      ...order,
      items: items || [],
      drops: drops || []
    };
  }
}

export default new OrderRepository();

