import axios from 'axios'

/**
 * Axios client instance configured with base URL
 */
const api = axios.create({
  baseURL: '/api/v2',
})

// Request Interceptor: Thêm access token vào header nếu có
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response Interceptor: Xử lý khi token hết hạn hoặc lỗi 401, hiển thị thông báo lỗi
api.interceptors.response.use(
  (response) => response.data,
  async (error) => {
    if (error.response) {
      if (error.response.status === 401) {
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        localStorage.removeItem('user')
        if (window.location.hash !== '#/login') {
          window.location.href = '#/login'
        }
      } else {
        let errMsg = error.response.data?.message || error.response.data?.detail
        if (!errMsg && error.response.data && typeof error.response.data === 'object') {
          errMsg = Object.entries(error.response.data)
            .map(([field, msgs]) => `${field}: ${Array.isArray(msgs) ? msgs.join(', ') : msgs}`)
            .join('\n')
        }
        if (!errMsg) {
          errMsg = 'Đã xảy ra lỗi hệ thống.'
        }
        alert(`Lỗi:\n${errMsg}`)
      }
    } else {
      alert('Không thể kết nối tới máy chủ. Vui lòng kiểm tra lại kết nối mạng.')
    }
    return Promise.reject(error)
  }
)

export default api
