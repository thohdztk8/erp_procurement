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

// Response Interceptor: Xử lý khi token hết hạn hoặc lỗi 401
api.interceptors.response.use(
  (response) => response.data,
  async (error) => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('access_token')
      localStorage.removeItem('refresh_token')
      localStorage.removeItem('user')
      if (window.location.hash !== '#/login') {
        window.location.href = '#/login'
      }
    }
    return Promise.reject(error)
  }
)

export default api
