import {
  mdiMonitor,
  mdiDatabase,
  mdiNotebook,
  mdiCart,
  mdiCompare,
  mdiFileDocument,
  mdiWarehouse,
  mdiCashRegister,
  mdiAccountCircle,
  mdiLogout,
} from '@mdi/js'

export const menuAsideMain = [
  {
    to: '/dashboard',
    icon: mdiMonitor,
    label: 'Dashboard / Yêu cầu (PR)',
  },
  {
    to: '/master-data',
    icon: mdiDatabase,
    label: 'Dữ liệu gốc (Master)',
  },
  {
    to: '/cart-orders',
    icon: mdiCart,
    label: 'Giỏ hàng & Đơn mua (PO)',
  },
  {
    to: '/quotations',
    icon: mdiCompare,
    label: 'Đấu thầu & Báo giá',
  },
  {
    to: '/contracts',
    icon: mdiFileDocument,
    label: 'Hợp đồng mua sắm (IPO)',
  },
  {
    to: '/warehouse',
    icon: mdiWarehouse,
    label: 'Kho & Nhập kho (GRN)',
  },
  {
    to: '/finance',
    icon: mdiCashRegister,
    label: 'Kế toán & Thanh toán',
  },
  {
    to: '/profile',
    icon: mdiAccountCircle,
    label: 'Thông tin cá nhân',
  },
]

export const menuAsideBottom = [
  {
    label: 'Đăng xuất',
    icon: mdiLogout,
    color: 'info',
    isLogout: true,
  },
]
