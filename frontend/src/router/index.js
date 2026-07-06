import { createRouter, createWebHashHistory } from 'vue-router'
import { menuAsideMain } from '@/menuAside.js'

const routes = [
  {
    path: '/',
    redirect: '/dashboard',
  },
  {
    meta: {
      title: 'Dashboard / PR',
    },
    path: '/dashboard',
    name: 'dashboard',
    component: () => import('@/views/HomeView.vue'),
  },
  {
    meta: {
      title: 'Dữ liệu gốc (Master Data)',
    },
    path: '/master-data',
    name: 'master-data',
    component: () => import('@/views/MasterDataView.vue'),
  },
  {
    meta: {
      title: 'Giỏ hàng & Đơn mua hàng (PO)',
    },
    path: '/cart-orders',
    name: 'cart-orders',
    component: () => import('@/views/CartOrderView.vue'),
  },
  {
    meta: {
      title: 'Đấu thầu & Báo giá',
    },
    path: '/quotations',
    name: 'quotations',
    component: () => import('@/views/QuotationView.vue'),
  },
  {
    meta: {
      title: 'Hợp đồng mua sắm (IPO)',
    },
    path: '/contracts',
    name: 'contracts',
    component: () => import('@/views/IpoView.vue'),
  },
  {
    meta: {
      title: 'Kho & Nhập kho (GRN)',
    },
    path: '/warehouse',
    name: 'warehouse',
    component: () => import('@/views/WarehouseView.vue'),
  },
  {
    meta: {
      title: 'Kế toán & Thanh toán',
    },
    path: '/finance',
    name: 'finance',
    component: () => import('@/views/FinanceView.vue'),
  },
  {
    meta: {
      title: 'Thông tin cá nhân',
    },
    path: '/profile',
    name: 'profile',
    component: () => import('@/views/ProfileView.vue'),
  },
  {
    meta: {
      title: 'Đăng nhập',
    },
    path: '/login',
    name: 'login',
    component: () => import('@/views/LoginView.vue'),
  },
  {
    meta: {
      title: 'Lỗi',
    },
    path: '/error',
    name: 'error',
    component: () => import('@/views/ErrorView.vue'),
  },
  {
    meta: {
      title: 'Vendor Portal',
    },
    path: '/vendor-portal',
    name: 'vendor-portal',
    component: () => import('@/views/VendorPortalView.vue'),
  },
]

const router = createRouter({
  history: createWebHashHistory(),
  routes,
  scrollBehavior(to, from, savedPosition) {
    return savedPosition || { top: 0 }
  },
})

export const getFirstAllowedRoute = () => {
  const user = JSON.parse(localStorage.getItem('user') || '{}')
  if (!user.username) return '/login'
  
  if (user.username === 'admin' || user.role_code === 'ADMIN') {
    return '/dashboard'
  }
  
  const userPermissions = user.permissions || []
  for (const item of menuAsideMain) {
    if (!item.permissions || item.permissions.length === 0) {
      return item.to
    }
    if (item.permissions.some(p => userPermissions.includes(p))) {
      return item.to
    }
  }
  return '/profile'
}

router.beforeEach((to, from, next) => {
  const isAuthenticated = !!localStorage.getItem('access_token')
  if (!isAuthenticated && to.name !== 'login' && to.name !== 'error' && to.name !== 'vendor-portal') {
    next({ name: 'login' })
  } else if (isAuthenticated && (to.name === 'login' || to.path === '/')) {
    next(getFirstAllowedRoute())
  } else if (isAuthenticated) {
    const user = JSON.parse(localStorage.getItem('user') || '{}')
    const username = user.username || ''
    const role_code = user.role_code || ''
    
    // Tìm item tương ứng trong menuAsideMain để kiểm tra quyền
    const matchedMenuItem = menuAsideMain.find(item => item.to === to.path)
    
    if (matchedMenuItem && matchedMenuItem.permissions && matchedMenuItem.permissions.length > 0) {
      if (username !== 'admin' && role_code !== 'ADMIN') {
        const userPermissions = user.permissions || []
        const hasPermission = matchedMenuItem.permissions.some(p => userPermissions.includes(p))
        if (!hasPermission) {
          // Không có quyền, chuyển hướng sang trang báo lỗi
          next({ name: 'error' })
          return
        }
      }
    }
    next()
  } else {
    next()
  }
})

export default router

