import api from './client'

/**
 * Finance service handling Invoices, 3-Way Matching, Payment Requests,
 * Credit/Debit Notes, Exports, Reports, System Configs, and Notifications.
 */
export const financeService = {
  /**
   * Create an invoice from supplier.
   * @param {object} data - Invoice data.
   * @returns {Promise<object>}
   */
  async createInvoice(data) {
    return await api.post('/invoice/create', data)
  },

  /**
   * Get list of invoices.
   * @returns {Promise<object>}
   */
  async getInvoices() {
    return await api.get('/invoice/')
  },

  /**
   * Get detailed invoice data.
   * @param {number|string} id - Invoice ID.
   * @returns {Promise<object>}
   */
  async getInvoiceDetail(id) {
    return await api.get(`/invoice/${id}`)
  },

  /**
   * Trigger 3-way matching algorithm.
   * @param {number|string} invoice_id - Invoice ID.
   * @returns {Promise<object>} Match outcome.
   */
  async verifyMatching(invoice_id) {
    return await api.post('/invoice/verify-matching', { invoice_id })
  },

  /**
   * Override a matching mismatch discrepancy.
   * @param {number|string} invoice_id - Invoice ID.
   * @param {string} reason - Justification.
   * @returns {Promise<object>}
   */
  async overrideMatching(invoice_id, reason) {
    return await api.post(`/invoice/${invoice_id}/override`, { comment: reason })
  },

  /**
   * Request invoice payment.
   * @param {number|string} invoice_id - Invoice ID.
   * @param {number} amount - Amount requested.
   * @returns {Promise<object>}
   */
  async createPaymentRequest(invoice_id, amount) {
    return await api.post('/invoice/payment/request', { invoice_id, amount })
  },

  /**
   * Get payment requests.
   * @returns {Promise<object>}
   */
  async getPayments() {
    return await api.get('/invoice/payment/')
  },

  /**
   * Process (approve/reject/pay) a payment request.
   * @param {number|string} payment_request_id - Request ID.
   * @param {string} action - Action taken.
   * @param {string} comment - Remarks.
   * @returns {Promise<object>}
   */
  async approvePayment(payment_request_id, action, comment) {
    return await api.post('/invoice/payment/approve', { payment_request_id, action, comment })
  },

  /**
   * Create credit note.
   * @param {object} data - Credit note details.
   * @returns {Promise<object>}
   */
  async createCreditNote(data) {
    return await api.post('/credit-notes', data)
  },

  /**
   * Create debit note.
   * @param {object} data - Debit note details.
   * @returns {Promise<object>}
   */
  async createDebitNote(data) {
    return await api.post('/debit-notes', data)
  },

  /**
   * Get list of credit notes.
   * @returns {Promise<object>}
   */
  async getCreditNotes() {
    return await api.get('/credit-notes')
  },

  /**
   * Get list of debit notes.
   * @returns {Promise<object>}
   */
  async getDebitNotes() {
    return await api.get('/debit-notes')
  },

  /**
   * Get dashboard summary and reporting KPIs.
   * @param {string} type - Report type (e.g. 'summary', 'po-status').
   * @param {object} params - Query filters.
   * @returns {Promise<object>} Reporting metrics.
   */
  async getReports(type, params) {
    return await api.get(`/reports/${type}`, { params })
  },

  /**
   * Get supported accounting export templates.
   * @returns {Promise<object>}
   */
  async getExportTemplates() {
    return await api.get('/accounting/export-templates')
  },

  /**
   * Trigger accounting data export.
   * @param {object} data - Selection criteria.
   * @returns {Promise<object>} Export file link.
   */
  async createExport(data) {
    return await api.post('/accounting/exports', data)
  },

  /**
   * Retrieve system configurations.
   * @returns {Promise<object>} System settings.
   */
  async getConfigs() {
    return await api.get('/system/configs')
  },

  /**
   * Update system configuration parameter.
   * @param {string} key - Config identifier.
   * @param {object} value - Value structure.
   * @returns {Promise<object>}
   */
  async updateConfig(key, value) {
    return await api.put(`/system/configs/${key}`, value)
  },

  /**
   * Get user notifications list.
   * @returns {Promise<object>}
   */
  async getNotifications() {
    return await api.get('/notifications')
  },

  /**
   * Mark a notification as read.
   * @param {number|string} id - Notification ID.
   * @returns {Promise<object>}
   */
  async markNotificationRead(id) {
    return await api.patch(`/notifications/${id}/mark-read`)
  }
}
