import api from './client'

/**
 * Master Data service handling users, materials, suppliers, permissions, and roles.
 */
export const masterService = {
  /**
   * Get materials list.
   * @returns {Promise<object>} Materials.
   */
  async getMaterials() {
    return await api.get('/master/materials')
  },

  /**
   * Create a new material.
   * @param {object} data - Material data.
   * @returns {Promise<object>} Created material.
   */
  async createMaterial(data) {
    return await api.post('/master/materials', data)
  },

  /**
   * Get suppliers list.
   * @returns {Promise<object>} Suppliers.
   */
  async getSuppliers() {
    return await api.get('/master/suppliers')
  },

  /**
   * Create a new supplier.
   * @param {object} data - Supplier data.
   * @returns {Promise<object>} Created supplier.
   */
  async createSupplier(data) {
    return await api.post('/master/suppliers', data)
  },

  /**
   * Add a contract price agreement for a supplier.
   * @param {number|string} supplierId - Supplier ID.
   * @param {object} data - Price agreement data.
   * @returns {Promise<object>}
   */
  async addContractPrice(supplierId, data) {
    return await api.post(`/suppliers/${supplierId}/contract-prices`, data)
  },

  /**
   * Get internal users list.
   * @returns {Promise<object>} Users.
   */
  async getUsers() {
    return await api.get('/users')
  },

  /**
   * Create a new user account.
   * @param {object} data - User details.
   * @returns {Promise<object>}
   */
  async createUser(data) {
    return await api.post('/users', data)
  },

  /**
   * Update user details or role.
   * @param {number|string} id - User ID.
   * @param {object} data - Updated details.
   * @returns {Promise<object>}
   */
  async updateUser(id, data) {
    return await api.put(`/users/${id}`, data)
  },

  /**
   * Deactivate user account (soft delete).
   * @param {number|string} id - User ID.
   * @returns {Promise<object>}
   */
  async deactivateUser(id) {
    return await api.patch(`/users/${id}/deactivate`)
  },

  /**
   * Get roles.
   * @returns {Promise<object>} Roles.
   */
  async getRoles() {
    return await api.get('/roles')
  },

  /**
   * Get system permissions.
   * @returns {Promise<object>} Permissions.
   */
  async getPermissions() {
    return await api.get('/permissions')
  },

  /**
   * Assign permissions to a role.
   * @param {number|string} roleId - Role ID.
   * @param {number[]} permissionIds - Array of permission IDs.
   * @returns {Promise<object>}
   */
  async updateRolePermissions(roleId, permissionIds) {
    return await api.put(`/roles/${roleId}/permissions`, { permission_ids: permissionIds })
  }
}
