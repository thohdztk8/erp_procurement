import api from './client'

/**
 * Cart and Purchase Order service.
 */
export const cartOrderService = {
  /**
   * Add items to the procurement cart.
   * @param {object[]} items - Cart items to add.
   * @returns {Promise<object>}
   */
  async addItemsToCart(items) {
    return await api.post('/cart/add-items', { items })
  },

  /**
   * Get cart details.
   * @param {number|string} id - Cart ID.
   * @returns {Promise<object>}
   */
  async getCart(id) {
    return await api.get(`/cart/${id}`)
  },

  /**
   * Convert procurement cart to purchase orders.
   * @param {number|string} cart_id - Cart ID.
   * @returns {Promise<object>}
   */
  async convertCartToOrder(cart_id) {
    return await api.post(`/cart/${cart_id}/convert`)
  },

  /**
   * Get orders list.
   * @returns {Promise<object>}
   */
  async getOrders() {
    return await api.get('/cart/orders')
  },

  /**
   * Get order detail.
   * @param {number|string} id - Order ID.
   * @returns {Promise<object>}
   */
  async getOrderDetail(id) {
    return await api.get(`/cart/orders/${id}`)
  },

  /**
   * Invite suppliers to bid on an order.
   * @param {number|string} order_id - Order ID.
   * @param {number[]} supplier_ids - Invited suppliers.
   * @returns {Promise<object>}
   */
  async addSuppliersToOrder(order_id, supplier_ids) {
    return await api.post(`/cart/orders/${order_id}/suppliers`, { supplier_ids })
  }
}
