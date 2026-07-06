import api from './client'

/**
 * Authentication service handling login, logout and profile fetching.
 */
export const authService = {
  /**
   * Log in user using username and password.
   * @param {string} username - User's login username.
   * @param {string} password - User's login password.
   * @returns {Promise<object>} Auth data with tokens and user info.
   */
  async login(username, password) {
    const response = await api.post('/auth/login', { username, password })
    const { access_token, refresh_token } = response.data
    localStorage.setItem('access_token', access_token)
    localStorage.setItem('refresh_token', refresh_token)
    
    const profile = await this.getProfile()
    localStorage.setItem('user', JSON.stringify(profile.data))
    return response.data
  },

  /**
   * Get authenticated user profile details.
   * @returns {Promise<object>} User profile details.
   */
  async getProfile() {
    return await api.get('/auth/profile')
  },
  
  /**
   * Cập nhật thông tin hồ sơ của người dùng hiện tại.
   * @param {object} data - Dữ liệu cập nhật bao gồm full_name, email, phone.
   * @returns {Promise<object>} Dữ liệu phản hồi từ API sau khi cập nhật.
   */
  async updateProfile(data) {
    return await api.put('/auth/profile', data)
  },

  /**
   * Thay đổi mật khẩu tài khoản người dùng hiện tại.
   * @param {object} data - Dữ liệu bao gồm password_current, password, password_confirmation.
   * @returns {Promise<object>} Dữ liệu phản hồi từ API sau khi cập nhật mật khẩu thành công.
   */
  async changePassword(data) {
    return await api.post('/auth/change-password', data)
  },

  /**
   * Log out current user and clear local storage tokens.
   * @returns {Promise<void>}
   */
  async logout() {
    const refresh = localStorage.getItem('refresh_token')
    if (refresh) {
      try {
        await api.post('/auth/logout', { refresh_token: refresh })
      } catch {
        // Ignore errors on logout
      }
    }
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('user')
  }
}
