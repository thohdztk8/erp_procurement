# Hệ Thống Quản Lý Mua Hàng — Backend API

> **Stack:** Python 3.12 · Django 5.x · Django REST Framework · MSSQL · Docker Compose
> **Phiên bản:** 1.0.0 · Tham chiếu: SRS v2.0 · DB Design v2.1 · API Spec v3.0

---

## Mục Lục

1. [Tổng Quan](#1-tổng-quan)
2. [Kiến Trúc](#2-kiến-trúc)
3. [Cấu Trúc Thư Mục](#3-cấu-trúc-thư-mục)
4. [Yêu Cầu Môi Trường](#4-yêu-cầu-môi-trường)
5. [Biến Môi Trường (.env)](#5-biến-môi-trường-env)
6. [Khởi Chạy với Docker Compose](#6-khởi-chạy-với-docker-compose)
7. [Quản Lý Database & Migration](#7-quản-lý-database--migration)
8. [Mô Tả Các Module](#8-mô-tả-các-module)
9. [API Endpoints Tổng Quan](#9-api-endpoints-tổng-quan)
10. [Chạy Tests](#10-chạy-tests)
11. [Quy Tắc Lập Trình](#11-quy-tắc-lập-trình)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Tổng Quan

Đây là **backend-only** của Hệ thống Quản lý Mua hàng Doanh nghiệp Sản xuất.

| Vai trò | Mô tả |
|---|---|
| **Backend (repo này)** | Django REST API + Django Admin. Không render HTML, không chứa frontend code. |
| **Frontend (repo riêng)** | ReactJS / Next.js / Vue — giao tiếp hoàn toàn qua REST API + JWT. |

**Backend đảm nhận:**
- Cung cấp toàn bộ REST API theo chuẩn `/api/v2/...`
- Quản trị hệ thống qua Django Admin (`/admin/`)
- Xác thực và phân quyền RBAC qua JWT (SimpleJWT)
- Xử lý nghiệp vụ: PR → Cart → Quotation → IPO → Warehouse → Invoice

**Frontend tự lo:**
- Lưu `access_token` / `refresh_token` nhận từ `/api/v2/auth/login`
- Đính kèm `Authorization: Bearer <token>` trên mọi request
- Tự refresh token khi hết hạn qua `/api/v2/auth/refresh`

---

## 2. Kiến Trúc

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker Network                          │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │  Nginx       │───▶│  Django App  │───▶│  MSSQL 2022   │  │
│  │  Port 80     │    │  Gunicorn    │    │  Port 1433    │  │
│  │  (Reverse    │    │  Port 8000   │    └───────────────┘  │
│  │   Proxy)     │    └──────┬───────┘                       │
│  └──────────────┘           │        ┌───────────────┐      │
│                             ├───────▶│  Redis        │      │
│                             │        │  Port 6379    │      │
│                             │        └───────────────┘      │
│                             │        ┌───────────────┐      │
│                             └───────▶│  Celery Worker│      │
│                                      │  (Email/Tasks)│      │
│                                      └───────────────┘      │
└─────────────────────────────────────────────────────────────┘

Frontend (repo riêng, port 3000) ──HTTP/JSON + JWT──▶ Nginx ──▶ Django API
```

**Luồng xác thực JWT:**
```
Frontend          Backend
   │── POST /api/v2/auth/login ──▶│  Trả về access_token + refresh_token
   │◀── {access_token, refresh} ──│
   │                              │
   │── GET /api/v2/pr/list ───────│  Header: Authorization: Bearer <access_token>
   │   (kèm Bearer token)        │
   │◀── {success, data, ...} ─────│
```

---

## 3. Cấu Trúc Thư Mục

```
procurement-backend/                  ← Root repo
│
├── Dockerfile                        ← Build Django app image
├── Dockerfile.dev                    ← Dev image (hot-reload)
├── docker-compose.yml                ← Production: app + db + redis + nginx + worker
├── docker-compose.dev.yml            ← Development: thêm volume mount, SQL debug log
├── docker-compose.test.yml           ← CI/Test environment
│
├── .env.example                      ← Template biến môi trường (commit vào git)
├── .env                              ← Biến môi trường thực (KHÔNG commit)
├── .gitignore
├── README.md
│
├── nginx/
│   └── default.conf                  ← Nginx reverse proxy config
│
└── src/                              ← Toàn bộ source code Python/Django
    │
    ├── manage.py
    │
    ├── config/                       ← Django project package (thay cho settings.py đơn)
    │   ├── __init__.py
    │   ├── urls.py                   ← Root URL: include từng app module
    │   ├── wsgi.py
    │   ├── asgi.py
    │   └── settings/
    │       ├── __init__.py
    │       ├── base.py               ← Cấu hình chung (apps, DRF, JWT, CORS, Celery)
    │       ├── development.py        ← Override DEV: DEBUG=True, console email, SQL log
    │       └── production.py         ← Override PROD: security headers, Gunicorn
    │
    ├── core/                         ← Thành phần dùng chung — KHÔNG chứa nghiệp vụ
    │   ├── __init__.py
    │   ├── exceptions/
    │   │   ├── __init__.py
    │   │   └── handlers.py           ← Custom DRF exception handler → chuẩn hóa lỗi
    │   ├── permissions/
    │   │   ├── __init__.py
    │   │   └── rbac.py               ← Permission class: kiểm tra permission_code từ JWT
    │   ├── pagination/
    │   │   ├── __init__.py
    │   │   └── standard.py           ← Pagination: page / page_size / total_items
    │   ├── renderers/
    │   │   ├── __init__.py
    │   │   └── api_renderer.py       ← JSONRenderer: bọc response thành {success,code,data}
    │   └── utils/
    │       ├── __init__.py
    │       ├── code_generator.py     ← Sinh mã chứng từ: PR-2026-00001, IPO-2026-00001
    │       ├── token_generator.py    ← Sinh & verify SHA-256 Token cho Vendor Portal
    │       └── audit.py              ← Helper ghi AuditLog tự động
    │
    ├── infrastructure/               ← Kết nối dịch vụ ngoài (email, celery)
    │   ├── __init__.py
    │   ├── middleware/
    │   │   ├── __init__.py
    │   │   └── audit_middleware.py   ← Ghi request log vào AuditLogs
    │   ├── tasks/
    │   │   ├── __init__.py
    │   │   ├── celery.py             ← Celery app instance
    │   │   └── email_tasks.py        ← Async tasks: mail mời báo giá, thông báo duyệt
    │   └── emails/
    │       ├── __init__.py
    │       └── sender.py             ← Email service wrapper
    │
    ├── scripts/
    │   ├── entrypoint.sh             ← Docker entrypoint: wait-for-db → migrate → start
    │   ├── wait_for_db.py            ← Poll MSSQL connection trước khi start Django
    │   └── seed_master_data.py       ← Chạy seed SQL vào DB lần đầu triển khai
    │
    └── apps/                         ← Toàn bộ business logic, chia theo module nghiệp vụ
        │
        ├── authentication/           ── Module 1: Xác thực & Phân quyền RBAC
        │   ├── __init__.py
        │   ├── models.py             ← Branches, Departments, Roles, Users,
        │   │                            Permissions, RolePermissions, AuditLogs
        │   ├── serializers.py        ← LoginSerializer, UserProfileSerializer
        │   ├── views.py              ← LoginView, RefreshView, LogoutView, ProfileView
        │   ├── urls.py               ← /auth/login · /auth/refresh · /auth/logout
        │   ├── services.py           ← AuthService: xác thực, lock account, phát JWT
        │   ├── admin.py              ← Đăng ký model vào Django Admin
        │   └── tests/
        │       ├── test_login.py
        │       └── test_rbac.py
        │
        ├── master_data/              ── Module 2: Danh mục gốc dùng chung
        │   ├── __init__.py
        │   ├── models.py             ← MaterialCategories, Materials, Suppliers,
        │   │                            SupplierContractPrices, ApprovalWorkflows,
        │   │                            ApprovalWorkflowSteps, SystemConfigs, EmailTemplates
        │   ├── serializers.py
        │   ├── views.py              ← CRUD Materials, Suppliers, ApprovalWorkflow config
        │   ├── urls.py
        │   ├── services.py           ← ApprovalMatrixService: resolve workflow theo amount
        │   ├── admin.py
        │   └── tests/
        │       └── test_approval_matrix.py
        │
        ├── purchase_request/         ── Module 3: Yêu cầu Mua hàng (PR)
        │   ├── __init__.py
        │   ├── models.py             ← PurchaseRequisitions, PRItems,
        │   │                            DocumentApprovalProgress, PRStatusHistory
        │   ├── serializers.py        ← PRCreateSerializer (cross-exclusion + urgent validate)
        │   ├── views.py              ← PRCreateView, PRListView, PRDetailView, PRApproveView
        │   ├── urls.py               ← /pr/create · /pr/ · /pr/{id} · /pr/approve
        │   │                            /pr/pending-list
        │   ├── services.py           ← PRService: tạo PR, khởi động approval workflow,
        │   │                            push notification URGENT
        │   ├── validators.py         ← Kiểm tra loại trừ chéo material_id vs material_name_other
        │   ├── admin.py
        │   └── tests/
        │       ├── test_pr_create.py
        │       └── test_pr_approval.py
        │
        ├── cart_order/               ── Module 4: Gom giỏ hàng & Điều phối đặt hàng
        │   ├── __init__.py
        │   ├── models.py             ← Carts, CartPRItems, Orders, OrderItems,
        │   │                            OrderItemPRLinks, OrderSuppliers
        │   ├── serializers.py
        │   ├── views.py              ← CartView, OrderView, AddItemsView
        │   ├── urls.py               ← /cart/add-items · /order/create
        │   │                            /order/{id}/suppliers
        │   ├── services.py           ← CartService: gom hàng, tổng hợp qty, tạo Order
        │   ├── admin.py
        │   └── tests/
        │       └── test_cart_aggregation.py
        │
        ├── quotation/                ── Module 5: Mời thầu & Cổng Portal NCC
        │   ├── __init__.py
        │   ├── models.py             ← QuotationRequests, QuotationTokens, Quotations,
        │   │                            QuotationItems, QuotationVersions
        │   ├── serializers.py        ← QuotationSubmitSerializer, TokenValidateSerializer
        │   ├── views.py              ← InviteView, VendorPortalSubmitView,
        │   │                            CompareView, SelectView
        │   ├── urls.py               ← /quotation/invite · /quotation/compare/{order_id}
        │   │                            /quotation/select
        │   ├── urls_portal.py        ← /vendor-portal/submit-bid  (public, no JWT)
        │   ├── services.py           ← QuotationService: sinh token SHA-256, gửi mail async,
        │   │                            version management, so sánh giá
        │   ├── admin.py
        │   └── tests/
        │       ├── test_token_security.py
        │       └── test_quotation_versioning.py
        │
        ├── ipo/                      ── Module 6: Đơn đặt hàng nội bộ (IPO) đa phiên bản
        │   ├── __init__.py
        │   ├── models.py             ← IPOs, IPOItems
        │   ├── serializers.py
        │   ├── views.py              ← IPOCreateVersionView, IPODetailView, IPOApproveView
        │   ├── urls.py               ← /ipo/create-version · /ipo/{id} · /ipo/approve
        │   ├── services.py           ← IPOService: tạo version mới, flip is_latest,
        │   │                            kiểm tra sum(qty_final) <= qty_requested
        │   ├── admin.py
        │   └── tests/
        │       ├── test_ipo_versioning.py
        │       └── test_qty_constraint.py
        │
        ├── warehouse/                ── Module 7: Kho vận — IQC, Nhận/Xuất/Trả hàng
        │   ├── __init__.py
        │   ├── models.py             ← WarehouseReceipts, WarehouseReceiptItems,
        │   │                            Inventory, WarehouseIssues, WarehouseReturns
        │   ├── serializers.py        ← ReceiptSerializer: validate qty_passed+qty_failed
        │   │                            =qty_received; photo_paths JSON array
        │   ├── views.py              ← ReceiptCreateView, IssueView, ReturnView,
        │   │                            InventoryListView
        │   ├── urls.py               ← /warehouse/receipt · /warehouse/issue
        │   │                            /warehouse/return · /warehouse/inventory
        │   ├── services.py           ← WarehouseService: cân bằng khối lượng IQC,
        │   │                            cập nhật Inventory trong atomic transaction
        │   ├── admin.py
        │   └── tests/
        │       ├── test_qty_balance.py
        │       └── test_inventory_transaction.py
        │
        └── invoice/                  ── Module 8: Hóa đơn, Đối soát 3 chiều & Thanh toán
            ├── __init__.py
            ├── models.py             ← Invoices, InvoiceItems, ThreeWayMatchingResults,
            │                            PaymentRequests, CreditNotes, DebitNotes,
            │                            SupplierEvaluations, SupplierEvaluationCriteria
            ├── serializers.py
            ├── views.py              ← InvoiceCreateView, VerifyMatchingView,
            │                            PaymentView, OverrideMatchingView,
            │                            CreditNoteView, DebitNoteView
            ├── urls.py               ← /invoice/create · /invoice/verify-matching
            │                            /invoice/{id}/override
            ├── urls_payment.py       ← /payment/request · /payment/approve
            ├── services.py           ← MatchingService: đối soát 3 chiều (qty_diff,
            │                            price_diff, is_error); PaymentService
            ├── admin.py
            └── tests/
                ├── test_three_way_matching.py
                └── test_override_flow.py
```

---

## 4. Yêu Cầu Môi Trường

| Công cụ | Phiên bản | Ghi chú |
|---|---|---|
| Docker | ≥ 24.x | [docs.docker.com](https://docs.docker.com/get-docker/) |
| Docker Compose | ≥ 2.x (plugin) | Tích hợp sẵn trong Docker Desktop |
| Git | ≥ 2.x | |

> Không cần cài Python, MSSQL hay Redis trực tiếp — tất cả chạy trong container.

---

## 5. Biến Môi Trường (.env)

Sao chép từ `.env.example` rồi điền giá trị thực:

```bash
cp .env.example .env
```

```dotenv
# ── Django ───────────────────────────────────────────────────
DJANGO_SETTINGS_MODULE=config.settings.development
SECRET_KEY=change-me-to-a-long-random-string
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# ── MSSQL ────────────────────────────────────────────────────
DB_NAME=ProcurementDB
DB_HOST=db                    # Tên service trong docker-compose
DB_PORT=1433
DB_USER=sa
DB_PASSWORD=YourStrong@Password123

# ── JWT ──────────────────────────────────────────────────────
JWT_ACCESS_TOKEN_LIFETIME_HOURS=8
JWT_REFRESH_TOKEN_LIFETIME_DAYS=7

# ── Redis / Celery ───────────────────────────────────────────
REDIS_URL=redis://redis:6379/0
CELERY_BROKER_URL=redis://redis:6379/1

# ── Email (SMTP) ─────────────────────────────────────────────
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=no-reply@company.com
EMAIL_HOST_PASSWORD=your-smtp-app-password

# ── Vendor Portal ────────────────────────────────────────────
VENDOR_PORTAL_BASE_URL=https://portal.company.com/vendor
QUOTATION_TOKEN_EXPIRE_HOURS=72

# ── File upload (ảnh IQC) ────────────────────────────────────
MEDIA_ROOT=/app/media
MAX_UPLOAD_SIZE_MB=10
```

> ⚠️ File `.env` **không được commit** vào git. Chỉ commit `.env.example`.

---

## 6. Khởi Chạy với Docker Compose

### Development

```bash
# Lần đầu: build image
docker compose -f docker-compose.dev.yml up --build

# Các lần sau
docker compose -f docker-compose.dev.yml up

# Chạy nền
docker compose -f docker-compose.dev.yml up -d
```

**Services và port:**

| Service | Container | Port |
|---|---|---|
| Django (dev server) | `procurement_app` | `8000` |
| MSSQL 2022 | `procurement_db` | `1433` |
| Redis | `procurement_redis` | `6379` |
| Celery Worker | `procurement_worker` | — |
| Nginx | `procurement_nginx` | `80` |

- **API:** `http://localhost:8000/api/v2/`
- **Django Admin:** `http://localhost:8000/admin/`

### Production

```bash
docker compose up --build -d
```

---

## 7. Quản Lý Database & Migration

### Khởi tạo lần đầu

```bash
# 1. Chạy migrations (tạo toàn bộ bảng)
docker compose -f docker-compose.dev.yml exec app python manage.py migrate

# 2. Nạp master data (Branches, Departments, Roles, Users mẫu, Materials...)
docker compose -f docker-compose.dev.yml exec app python manage.py seed_master_data

# 3. Tạo superuser cho Django Admin
docker compose -f docker-compose.dev.yml exec app python manage.py createsuperuser
```

### Tạo migration sau khi sửa model

```bash
# Một app cụ thể
docker compose -f docker-compose.dev.yml exec app \
    python manage.py makemigrations purchase_request

# Toàn bộ
docker compose -f docker-compose.dev.yml exec app \
    python manage.py makemigrations
```

### Thứ tự migration (phụ thuộc FK)

```
1. authentication    → Branches, Departments, Roles, Permissions, Users
2. master_data       → MaterialCategories, Materials, Suppliers, ApprovalWorkflows
3. purchase_request  → PurchaseRequisitions, PRItems
4. cart_order        → Carts, Orders, OrderItems, OrderSuppliers
5. quotation         → QuotationRequests, QuotationTokens, Quotations
6. ipo               → IPOs, IPOItems
7. warehouse         → WarehouseReceipts, Inventory
8. invoice           → Invoices, ThreeWayMatchingResults, PaymentRequests
```

---

## 8. Mô Tả Các Module

| App | Module | Bảng DB chính |
|---|---|---|
| `authentication` | Xác thực, RBAC, Audit Trail | `Users`, `Roles`, `Permissions`, `AuditLogs` |
| `master_data` | Danh mục vật tư, NCC, Ma trận phê duyệt | `Materials`, `Suppliers`, `ApprovalWorkflows` |
| `purchase_request` | Lập & duyệt PR Thường / Khẩn | `PurchaseRequisitions`, `PRItems`, `DocumentApprovalProgress` |
| `cart_order` | Gom giỏ hàng, tổng hợp khối lượng | `Carts`, `Orders`, `OrderItems`, `OrderSuppliers` |
| `quotation` | Mời báo giá, Vendor Portal Token SHA-256 | `QuotationTokens`, `Quotations`, `QuotationVersions` |
| `ipo` | Đơn đặt hàng nội bộ đa phiên bản | `IPOs`, `IPOItems` |
| `warehouse` | IQC, Nhận/Xuất/Trả kho, Inventory | `WarehouseReceipts`, `Inventory` |
| `invoice` | Hóa đơn, Đối soát 3 chiều, Thanh toán | `Invoices`, `ThreeWayMatchingResults`, `PaymentRequests` |

---

## 9. API Endpoints Tổng Quan

**Base URL:** `/api/v2/`

**Header bắt buộc** (trừ login và vendor-portal):
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Response chuẩn:**
```json
{
  "success": true,
  "code": 200,
  "message": "Thao tác thành công.",
  "data": {},
  "timestamp": "2026-05-27T08:30:00Z"
}
```

| Method | Endpoint | Quyền | Mô tả |
|---|---|---|---|
| `POST` | `/auth/login` | Public | Đăng nhập, nhận JWT |
| `POST` | `/auth/refresh` | Public | Làm mới access token |
| `POST` | `/auth/logout` | Đã đăng nhập | Blacklist refresh token |
| `GET` | `/master/materials` | Đã đăng nhập | Danh sách vật tư (full-text search) |
| `GET` | `/master/suppliers` | Đã đăng nhập | Danh sách nhà cung cấp |
| `POST` | `/pr/create` | `PR_CREATE` | Tạo đơn PR |
| `GET` | `/pr/pending-list` | `PR_APPROVE` | PR chờ tôi duyệt |
| `POST` | `/pr/approve` | `PR_APPROVE` | Phê duyệt / Từ chối PR |
| `POST` | `/cart/add-items` | `CART_CREATE` | Gom dòng hàng PR vào giỏ |
| `POST` | `/quotation/invite` | `QUOTATION_INVITE` | Gửi mời báo giá + Token SHA-256 |
| `POST` | `/vendor-portal/submit-bid` | Public (Token) | NCC nộp báo giá |
| `POST` | `/ipo/create-version` | `IPO_CREATE` | Tạo / cập nhật phiên bản IPO |
| `POST` | `/ipo/approve` | `IPO_APPROVE` | Phê duyệt IPO |
| `POST` | `/warehouse/receipt` | `WH_RECEIPT` | Lập phiếu nhập kho + IQC |
| `POST` | `/invoice/verify-matching` | `INV_MATCHING` | Đối soát 3 chiều |
| `POST` | `/invoice/{id}/override` | `OVERRIDE_MATCHING` | Override sai lệch (BGĐ) |

> Chi tiết đầy đủ xem `docs/api_document_v2.md`

---

## 10. Chạy Tests

```bash
# Toàn bộ test suite
docker compose -f docker-compose.test.yml run --rm app pytest

# Một module cụ thể
docker compose -f docker-compose.test.yml run --rm app \
    pytest src/apps/purchase_request/tests/ -v

# Kèm coverage report
docker compose -f docker-compose.test.yml run --rm app \
    pytest --cov=apps --cov-report=html
```

---

## 11. Quy Tắc Lập Trình

### Phân tầng trong mỗi App

```
views.py       ← Nhận request → gọi serializer validate → gọi service → trả Response
serializers.py ← Validate field-level và object-level (không chứa DB query)
services.py    ← Toàn bộ business logic + DB transaction (atomic khi cần)
models.py      ← Định nghĩa model + DB constraints (không chứa business logic)
admin.py       ← Đăng ký model vào Django Admin
```

**Quy tắc bắt buộc:**
- `views.py` **không** được chứa business logic hay query DB trực tiếp
- Mọi thao tác thay đổi `Inventory` **phải** bọc trong `transaction.atomic()`
- Tuyệt đối dùng **Django ORM / parameterized query** — không raw SQL thuần
- Soft delete only: set `is_active = False`, không `DELETE` vật lý
- Mọi ghi/sửa dữ liệu phải ghi kèm `AuditLog`
- Mật khẩu hash bằng BCrypt, Token Vendor Portal hash SHA-256

---

## 12. Troubleshooting

**App không kết nối được DB:**
```bash
docker compose logs db | tail -30
# MSSQL mất ~30s để khởi động lần đầu
```

**Lỗi ODBC Driver:**
```bash
docker compose exec app odbcinst -q -d
# Mong đợi: [ODBC Driver 17 for SQL Server]
```

**Reset DB hoàn toàn (DEV):**
```bash
docker compose -f docker-compose.dev.yml down -v   # xóa volumes
docker compose -f docker-compose.dev.yml up --build -d
docker compose -f docker-compose.dev.yml exec app python manage.py migrate
docker compose -f docker-compose.dev.yml exec app python manage.py seed_master_data
```

**Xem log realtime:**
```bash
docker compose -f docker-compose.dev.yml logs -f app worker
```
