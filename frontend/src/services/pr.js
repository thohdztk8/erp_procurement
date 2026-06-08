import api from './client'

/**
 * Purchase Request service handling PR lifecycle.
 */
export const prService = {
  /**
   * Get list of PRs.
   * @param {string} [status] - Filter by status.
   * @returns {Promise<object>} List of PRs.
   */
  async getPRs(status) {
    const params = {}
    if (status) {
      params.status = status
    }
    return await api.get('/pr/', { params })
  },

  /**
   * Get PR detail.
   * @param {number|string} id - PR ID.
   * @returns {Promise<object>} Detailed PR information.
   */
  async getPRDetail(id) {
    return await api.get(`/pr/${id}`)
  },

  /**
   * Create new PR.
   * @param {object} data - PR payload.
   * @returns {Promise<object>} Created PR object.
   */
  async createPR(data) {
    return await api.post('/pr/create', data)
  },

  /**
   * Submit PR for approval.
   * @param {number|string} id - PR ID.
   * @returns {Promise<object>} Submission result.
   */
  async submitPR(id) {
    return await api.post(`/pr/${id}/submit`)
  },

  /**
   * Approve or reject a PR.
   * @param {number|string} pr_id - PR ID.
   * @param {string} action - APPROVE or REJECT.
   * @param {string} comment - Reason or remarks.
   * @returns {Promise<object>} Approval response.
   */
  async approvePR(pr_id, action, comment) {
    return await api.post('/pr/approve', { pr_id, action, comment })
  },

  /**
   * Get list of PRs pending current user's approval.
   * @returns {Promise<object>} Pending PRs.
   */
  async getPendingPRs() {
    return await api.get('/pr/pending-list')
  }
}
