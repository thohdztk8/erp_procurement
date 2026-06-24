import api from './client'

/**
 * Internal Purchase Order (IPO) service.
 */
export const ipoService = {
  /**
   * Get list of IPOs.
   * @returns {Promise<object>}
   */
  async getIPOs(params = {}) {
    return await api.get('/ipo/', { params })
  },

  /**
   * Get details of a specific IPO.
   * @param {number|string} id - IPO ID.
   * @returns {Promise<object>}
   */
  async getIPODetail(id) {
    return await api.get(`/ipo/${id}`)
  },

  /**
   * Submit IPO for approval.
   * @param {number|string} id - IPO ID.
   * @returns {Promise<object>}
   */
  async submitIPO(id) {
    return await api.post(`/ipo/${id}/submit`)
  },

  /**
   * Approve or reject IPO.
   * @param {number|string} ipo_id - IPO ID.
   * @param {string} action - APPROVE or REJECT.
   * @param {string} comment - Approver remarks.
   * @returns {Promise<object>}
   */
  async approveIPO(ipo_id, action, comment) {
    return await api.post('/ipo/approve', { ipo_id, action, comment })
  },

  /**
   * Create or update IPO version.
   * @param {object} payload - { order_id, supplier_id, items: [{order_item_id, qty_final, unit_price}] }
   * @returns {Promise<object>}
   */
  async createIPOVersion(payload) {
    return await api.post('/ipo/create-version', payload)
  }
}
