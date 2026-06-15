import api from './client'

/**
 * Quotation & Vendor Portal service.
 */
export const quotationService = {
  /**
   * Invite suppliers to bid on an order with a deadline.
   * @param {number|string} order_id - Order ID.
   * @param {number[]} supplier_ids - List of supplier IDs.
   * @param {string} deadline - Bidding deadline.
   * @param {boolean} override_rule - True to skip rules.
   * @returns {Promise<object>}
   */
  async inviteSuppliers(order_id, supplier_ids, deadline, override_rule = false) {
    return await api.post('/quotation/invite', { order_id, supplier_ids, deadline_submission: deadline, override_rule })
  },

  /**
   * Compare quotations for a specific order.
   * @param {number|string} order_id - Order ID.
   * @returns {Promise<object>}
   */
  async compareQuotations(order_id) {
    return await api.get(`/quotation/compare/${order_id}`)
  },

  /**
   * Select winning quotation.
   * @param {number|string} quotation_id - Winning quotation ID.
   * @param {string} reason - Selection justification.
   * @returns {Promise<object>}
   */
  async selectQuotation(quotation_id, reason) {
    return await api.post('/quotation/select', { quotation_id, reason })
  },

  /**
   * Vendor Portal: Get details by token.
   * @param {string} token
   * @returns {Promise<object>}
   */
  async getVendorPortalDetail(token) {
    return await api.get(`/vendor-portal/detail?token=${token}`)
  },

  /**
   * Vendor Portal: Submit bid using token.
   * @param {object} payload - Includes token, delivery_lead_time_days, etc.
   * @returns {Promise<object>}
   */
  async submitVendorBid(payload) {
    return await api.post('/vendor-portal/submit-bid', payload)
  }
}
