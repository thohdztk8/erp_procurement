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
   * @returns {Promise<object>}
   */
  async inviteSuppliers(order_id, supplier_ids, deadline) {
    return await api.post('/quotation/invite', { order_id, supplier_ids, deadline })
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
  }
}
