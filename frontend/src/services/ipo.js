import api from './client'

/**
 * Internal Purchase Order (IPO) service.
 */
export const ipoService = {
  /**
   * Get list of IPOs.
   * @returns {Promise<object>}
   */
  async getIPOs() {
    return await api.get('/ipo/')
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
  }
}
