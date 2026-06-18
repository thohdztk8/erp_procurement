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
  async addItemsToCart(payload) {
    return await api.post('/cart/add-items', payload)
  },

  /**
   * Get list of carts.
   * @returns {Promise<object>}
   */
  async getCarts(params = {}) {
    return await api.get('/cart/', { params })
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
   * Update item quantity in cart.
   * @param {number|string} cart_id 
   * @param {number|string} pr_item_id 
   * @param {number} qty_in_cart 
   */
  async updateCartItem(cart_id, pr_item_id, qty_in_cart) {
    return await api.put(`/cart/${cart_id}/items/${pr_item_id}`, { qty_in_cart })
  },

  /**
   * Remove item from cart.
   * @param {number|string} cart_id 
   * @param {number|string} pr_item_id 
   */
  async removeCartItem(cart_id, pr_item_id) {
    return await api.delete(`/cart/${cart_id}/items/${pr_item_id}`)
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
  async getOrders(params = {}) {
    return await api.get('/cart/orders', { params })
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
  },

  /**
   * Update order (edit items, edit suppliers).
   * @param {number|string} order_id
   * @param {object} payload - { items: [], suppliers: [] }
   */
  async updateOrder(order_id, payload) {
    return await api.put(`/cart/orders/${order_id}/update`, payload)
  },

  /**
   * Update order status.
   * @param {number|string} order_id
   * @param {string} status - New status.
   */
  async updateOrderStatus(order_id, status) {
    return await api.put(`/cart/orders/${order_id}/status`, { status })
  }
}
