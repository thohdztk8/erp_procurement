import api from './client'

/**
 * Warehouse & Inventory service.
 */
export const warehouseService = {
  /**
   * Create a stock receipt (GRN) with IQC checks.
   * @param {object} data - GRN & IQC data.
   * @returns {Promise<object>}
   */
  async createReceipt(data) {
    return await api.post('/warehouse/receipt', data)
  },

  /**
   * Get list of receipts.
   * @returns {Promise<object>}
   */
  async getReceipts(params = {}) {
    return await api.get('/warehouse/receipts', { params })
  },

  /**
   * Get details of a stock receipt.
   * @param {number|string} id - Receipt ID.
   * @returns {Promise<object>}
   */
  async getReceiptDetail(id) {
    return await api.get(`/warehouse/receipt/${id}`)
  },

  /**
   * Get current stock inventory.
   * @returns {Promise<object>}
   */
  async getInventory(params = {}) {
    return await api.get('/warehouse/inventory', { params })
  },

  /**
   * Create an internal issue voucher.
   * @param {object} data - Issue details.
   * @returns {Promise<object>}
   */
  async createIssue(data) {
    return await api.post('/warehouse/issues/create', data)
  },

  /**
   * Get list of internal issues.
   * @returns {Promise<object>}
   */
  async getIssues(params = {}) {
    return await api.get('/warehouse/issues', { params })
  },

  /**
   * Department head confirms receipt of issued items.
   * @param {number|string} issueId - Issue ID.
   * @param {object} data - Quality rating comments and status.
   * @returns {Promise<object>}
   */
  async confirmIssueReceipt(issueId, data) {
    return await api.post(`/warehouse/issues/${issueId}/confirm-receipt`, data)
  },

  /**
   * Create a supplier return order.
   * @param {object} data - Return details.
   * @returns {Promise<object>}
   */
  async createReturnOrder(data) {
    return await api.post('/warehouse/return-orders/create', data)
  },

  /**
   * Get return orders list.
   * @returns {Promise<object>}
   */
  async getReturnOrders(params = {}) {
    return await api.get('/warehouse/return-orders', { params })
  },

  /**
   * Update return order status (e.g. SENT, RESOLVED).
   * @param {number|string} returnId - Return Order ID.
   * @param {object} data - Status and notes.
   * @returns {Promise<object>}
   */
  async updateReturnStatus(returnId, data) {
    return await api.patch(`/warehouse/return-orders/${returnId}/status`, data)
  },

  /**
   * Get stock movement history for a material.
   * @param {number|string} materialId - Material ID.
   * @returns {Promise<object>} Movement history.
   */
  async getMovementHistory(materialId) {
    return await api.get(`/warehouse/stock/${materialId}/movement-history`)
  }
}
