import axios from 'axios'

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

export const authService = {
  async login(username, password) {
    const response = await api.post('/auth/login', { username, password })
    const { access_token, refresh_token } = response.data
    localStorage.setItem('access_token', access_token)
    localStorage.setItem('refresh_token', refresh_token)
    
    // Fetch profile to save user info
    const profile = await this.getProfile()
    localStorage.setItem('user', JSON.stringify(profile.data))
    return response.data
  },
  async getProfile() {
    return await api.get('/auth/profile')
  },
  async logout() {
    const refresh = localStorage.getItem('refresh_token')
    if (refresh) {
      try {
        await api.post('/auth/logout', { refresh_token: refresh })
      } catch (e) {
        // Bỏ qua lỗi
      }
    }
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('user')
  }
}

export const prService = {
  async getPRs(status) {
    const params = {}
    if (status) {
      params.status = status
    }
    return await api.get('/pr/', { params })
  },
  async getPRDetail(id) {
    return await api.get(`/pr/${id}`)
  },
  async createPR(data) {
    return await api.post('/pr/create', data)
  },
  async submitPR(id) {
    return await api.post(`/pr/${id}/submit`)
  },
  async approvePR(pr_id, action, comment) {
    return await api.post('/pr/approve', { pr_id, action, comment })
  },
  async getPendingPRs() {
    return await api.get('/pr/pending-list')
  }
}

export const masterService = {
  async getMaterials() {
    return await api.get('/master/materials')
  },
  async getSuppliers() {
    return await api.get('/master/suppliers')
  }
}

export const cartOrderService = {
  async addItemsToCart(items) {
    return await api.post('/cart/add-items', { items })
  },
  async getCart(id) {
    return await api.get(`/cart/${id}`)
  },
  async convertCartToOrder(cart_id) {
    return await api.post(`/cart/${cart_id}/convert`)
  },
  async getOrders() {
    return await api.get('/cart/orders')
  },
  async getOrderDetail(id) {
    return await api.get(`/cart/orders/${id}`)
  },
  async addSuppliersToOrder(order_id, supplier_ids) {
    return await api.post(`/cart/orders/${order_id}/suppliers`, { supplier_ids })
  }
}

export const quotationService = {
  async inviteSuppliers(order_id, supplier_ids, deadline) {
    return await api.post('/quotation/invite', { order_id, supplier_ids, deadline })
  },
  async compareQuotations(order_id) {
    return await api.get(`/quotation/compare/${order_id}`)
  },
  async selectQuotation(quotation_id, reason) {
    return await api.post('/quotation/select', { quotation_id, reason })
  }
}

export const ipoService = {
  async getIPOs() {
    return await api.get('/ipo/')
  },
  async getIPODetail(id) {
    return await api.get(`/ipo/${id}`)
  },
  async submitIPO(id) {
    return await api.post(`/ipo/${id}/submit`)
  },
  async approveIPO(ipo_id, action, comment) {
    return await api.post('/ipo/approve', { ipo_id, action, comment })
  }
}

export const warehouseService = {
  async createReceipt(data) {
    return await api.post('/warehouse/receipt', data)
  },
  async getReceiptDetail(id) {
    return await api.get(`/warehouse/receipt/${id}`)
  },
  async getInventory() {
    return await api.get('/warehouse/inventory')
  }
}

export const financeService = {
  async createInvoice(data) {
    return await api.post('/invoice/create', data)
  },
  async getInvoices() {
    return await api.get('/invoice/')
  },
  async getInvoiceDetail(id) {
    return await api.get(`/invoice/${id}`)
  },
  async verifyMatching(invoice_id) {
    return await api.post('/invoice/verify-matching', { invoice_id })
  },
  async overrideMatching(invoice_id, reason) {
    return await api.post(`/invoice/${invoice_id}/override`, { comment: reason })
  },
  async createPaymentRequest(invoice_id, amount) {
    return await api.post('/invoice/payment/request', { invoice_id, amount })
  },
  async getPayments() {
    return await api.get('/invoice/payment/')
  },
  async approvePayment(payment_request_id, action, comment) {
    return await api.post('/invoice/payment/approve', { payment_request_id, action, comment })
  }
}

export default api
