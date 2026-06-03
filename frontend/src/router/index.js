import { createRouter, createWebHashHistory } from 'vue-router'

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
]

const router = createRouter({
  history: createWebHashHistory(),
  routes,
  scrollBehavior(to, from, savedPosition) {
    return savedPosition || { top: 0 }
  },
})

router.beforeEach((to, from, next) => {
  const isAuthenticated = !!localStorage.getItem('access_token')
  if (!isAuthenticated && to.name !== 'login' && to.name !== 'error') {
    next({ name: 'login' })
  } else if (isAuthenticated && (to.name === 'login' || to.path === '/')) {
    next({ name: 'dashboard' })
  } else {
    next()
  }
})

export default router

