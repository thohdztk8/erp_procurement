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
    label: 'Yêu cầu (PR)',
    permissions: ['PR_VIEW_ALL', 'PR_CREATE', 'PR_APPROVE'],
  },
  {
    to: '/master-data',
    icon: mdiDatabase,
    label: 'Dữ liệu gốc (Master)',
    permissions: ['SUPPLIER_CREATE', 'SUPPLIER_EDIT', 'MATERIAL_CREATE', 'MATERIAL_EDIT', 'CONFIG_VIEW'],
  },
  {
    to: '/cart-orders',
    icon: mdiCart,
    label: 'Giỏ hàng & Đơn mua (PO)',
    permissions: ['CART_CREATE', 'ORDER_CREATE'],
  },
  {
    to: '/quotations',
    icon: mdiCompare,
    label: 'Đấu thầu & Báo giá',
    permissions: ['ORDER_SEND_QUOTE'],
  },
  {
    to: '/contracts',
    icon: mdiFileDocument,
    label: 'Hợp đồng mua sắm (IPO)',
    permissions: ['IPO_VIEW_ALL', 'IPO_CREATE', 'IPO_APPROVE'],
  },
  {
    to: '/warehouse',
    icon: mdiWarehouse,
    label: 'Kho & Nhập kho (GRN)',
    permissions: ['WH_INVENTORY_VIEW', 'WH_RECEIPT_CREATE', 'WH_ISSUE_CREATE', 'WH_RETURN_CREATE'],
  },
  {
    to: '/finance',
    icon: mdiCashRegister,
    label: 'Kế toán & Thanh toán',
    permissions: ['INV_CREATE', 'INV_MATCH_RUN', 'PAYMENT_CREATE', 'PAYMENT_APPROVE'],
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
