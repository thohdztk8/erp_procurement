# TÀI LIỆU ĐẶC TẢ API (API SPECIFICATION DOCUMENT)

**Dự án:** Hệ Thống Quản Lý Mua Hàng Doanh Nghiệp Sản Xuất
**Phiên bản:** 3.0 (Đồng bộ toàn diện URD v2.0, UseCase v2.0, DB Design v2.0, SRS v2.0)
**Ngày cập nhật:** 26/05/2026
**Công nghệ Backend:** Python + Django REST Framework
**Hệ quản trị DB:** Microsoft SQL Server (MSSQL)
**Chuẩn đóng gói dữ liệu:** JSON (UTF-8)

> **Ghi chú phiên bản 3.0:** Tài liệu này được làm lại toàn bộ để phủ đủ 30 Use-Case của UseCase v2.0, sửa các mâu thuẫn enum/status với DB Design, bổ sung các endpoint còn thiếu cho payment, warehouse, reporting, kế toán export, đánh giá NCC và Credit/Debit Note. Chi tiết thay đổi tại Phụ lục §11.

---

## MỤC LỤC

1. Quy chuẩn kỹ thuật & I/O
2. Module 1 — Authentication & RBAC
3. Module 2 — Master Data (Material, Supplier, User, Permission)
4. Module 3 — Purchase Request (PR)
5. Module 4 — Cart & Order
6. Module 5 — Quotation & Vendor Portal
7. Module 6 — Internal PO (IPO) đa phiên bản
8. Module 7 — Warehouse (Receipt, Issue, Return, Inventory)
9. Module 8 — Invoice, 3-Way Matching, Payment, Credit/Debit Note
10. Module 9 — Reporting, Export kế toán, Supplier Evaluation, Audit Log, System Config
11. Phụ lục — Mã trạng thái, Bảng đối chiếu UC ↔ API, Lịch sử thay đổi v3.0

---

## 1. QUY CHUẨN KỸ THUẬT & TIÊU CHUẨN ĐẦU VÀO / ĐẦU RA

### 1.1 Môi trường triển khai (Base URL)

| Môi trường | Base URL |
| :--- | :--- |
| Development | `https://dev-api.procurement-system.local/api/v2` |
| Staging | `https://staging-api.procurement-system.local/api/v2` |
| Production | `https://api.procurement-system.local/api/v2` |

> Tất cả endpoint dưới đây được hiểu là đứng sau Base URL tương ứng. Ví dụ `/auth/login` thực tế là `POST {base_url}/auth/login`.

### 1.2 Global Headers

Mọi request (ngoại trừ `POST /auth/login` và `POST /vendor-portal/submit-bid`) bắt buộc có:

| Header | Kiểu | Vai trò | Ví dụ giá trị |
| :--- | :--- | :--- | :--- |
| `Content-Type` | String | Định dạng dữ liệu | `application/json` |
| `Accept` | String | Định dạng phản hồi | `application/json` |
| `Authorization` | String | JWT Bearer Token | `Bearer eyJhbGc...` |
| `Accept-Language` | String | Ngôn ngữ thông báo (mặc định `vi`) | `vi`, `en` |

### 1.3 Cấu trúc Response chuẩn

**Thành công (200 OK / 201 Created):**

```json
{
  "success": true,
  "code": 200,
  "message": "Thao tác thành công.",
  "data": { },
  "timestamp": "2026-05-26T08:30:00Z"
}
```

**Thành công có phân trang:**

```json
{
  "success": true,
  "code": 200,
  "message": "Truy xuất danh sách thành công.",
  "data": {
    "items": [],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total_items": 145,
      "total_pages": 8
    }
  },
  "timestamp": "2026-05-26T08:30:00Z"
}
```

**Thất bại / Lỗi nghiệp vụ:**

```json
{
  "success": false,
  "code": 422,
  "message": "Dữ liệu đầu vào không hợp lệ hoặc vi phạm logic nghiệp vụ.",
  "errors": {
    "field_name": ["Mô tả lỗi cụ thể."]
  },
  "trace_id": "req-2026-05-26-0a3f9e",
  "timestamp": "2026-05-26T08:30:01Z"
}
```

### 1.4 HTTP Status Codes áp dụng

| Code | Ý nghĩa |
| :--- | :--- |
| `200 OK` | Truy vấn / cập nhật thành công |
| `201 Created` | Tạo mới chứng từ / tài nguyên thành công |
| `204 No Content` | Xóa logic thành công (không có body) |
| `400 Bad Request` | Sai logic nghiệp vụ (nộp thầu quá hạn, chốt đơn chưa gom hàng...) |
| `401 Unauthorized` | Token sai / hết hạn / chưa cấp |
| `403 Forbidden` | Tài khoản hợp lệ nhưng RBAC không cho phép thao tác |
| `404 Not Found` | Tài nguyên không tồn tại hoặc đã bị tắt kích hoạt |
| `409 Conflict` | Trùng dữ liệu unique (trùng mã PR, trùng MST NCC...) |
| `422 Unprocessable Entity` | Lỗi validate dữ liệu / vi phạm CHECK constraint |
| `429 Too Many Requests` | Vượt quota rate-limit |
| `500 Internal Server Error` | Lỗi backend / xung đột transaction database |

### 1.5 Quy ước query parameter dùng chung cho các endpoint GET danh sách

| Param | Kiểu | Mô tả |
| :--- | :--- | :--- |
| `page` | Integer | Trang (mặc định 1) |
| `page_size` | Integer | Số dòng / trang (mặc định 20, tối đa 100) |
| `sort` | String | Trường sắp xếp + chiều (ví dụ `-created_at`) |
| `keyword` | String | Tìm kiếm tự do trên các trường tên/mã |
| `date_from`, `date_to` | ISO-8601 Date | Lọc theo khoảng thời gian |
| `status` | String | Lọc theo trạng thái chứng từ |

### 1.6 Quy ước Enum thống nhất toàn hệ thống

| Domain | Giá trị hợp lệ |
| :--- | :--- |
| `priority_level` (PR) | `NORMAL`, `URGENT` |
| `pr_status` | `DRAFT`, `PENDING`, `APPROVED`, `REJECTED`, `CANCELLED` |
| `cart_status` | `OPEN`, `CONVERTED`, `CANCELLED` |
| `order_status` | `DRAFT`, `QUOTING`, `QUOTE_CLOSED`, `COMPLETED`, `CANCELLED` |
| `ipo_status` | `DRAFT`, `PENDING`, `APPROVED`, `REJECTED` |
| `matching_status` | `PENDING`, `MATCHED`, `MISMATCHED` |
| `payment_req_status` | `PENDING`, `APPROVED`, `PAID`, `REJECTED` |
| `return_status` | `DRAFT`, `SENT`, `RESOLVED` |
| `approval_action` | `APPROVE`, `REJECT` |
| `approval_status` (step) | `PENDING`, `APPROVED`, `REJECTED` |

> **Lưu ý quan trọng (sửa từ v2.0):** Toàn bộ enum đã được sync khớp 1-1 với CHECK constraint trong `procedure.sql`. Mọi giá trị khác như `HIGH`, `DISCREPANCY`, `DRAFT_PENDING_SCAN`, `ORDERED` xuất hiện ở v2.0 đều **đã bỏ**.

---

## 2. MODULE 1 — AUTHENTICATION & RBAC

### 2.1 `POST /auth/login` — Đăng nhập cấp JWT Token

* **Authentication:** Không yêu cầu (Public)
* **Use Case tham chiếu:** UC-01

**Request Body:**

```json
{
  "username": "hoang.nv",
  "password": "SecretPassword@2026"
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "message": "Đăng nhập hệ thống thành công.",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6...",
    "token_type": "Bearer",
    "expires_in": 28800,
    "user": {
      "user_id": 12,
      "username": "hoang.nv",
      "full_name": "Nguyễn Văn Hoàng",
      "role_code": "BUYER",
      "branch_id": 1,
      "dept_id": 4,
      "permissions": ["PR_VIEW", "CART_CREATE", "ORDER_CREATE", "QUOTATION_INVITE"]
    }
  }
}
```

**Response lỗi (401 Unauthorized) — Sai mật khẩu:**

```json
{
  "success": false,
  "code": 401,
  "message": "Tên đăng nhập hoặc mật khẩu không chính xác.",
  "errors": null,
  "timestamp": "2026-05-26T08:30:01Z"
}
```

**Response lỗi (403 Forbidden) — Tài khoản bị khóa tạm thời (URD §4.1):**

```json
{
  "success": false,
  "code": 403,
  "message": "Tài khoản đã bị khóa do nhập sai mật khẩu quá 5 lần liên tiếp. Vui lòng thử lại sau 30 phút.",
  "errors": {
    "locked_until": "2026-05-26T09:00:00Z"
  },
  "timestamp": "2026-05-26T08:30:01Z"
}
```

### 2.2 `POST /auth/refresh-token` — Làm mới Token

**Request Body:**

```json
{ "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6..." }
```

**Response (200 OK):** Trả về `access_token` mới, `expires_in`.

### 2.3 `POST /auth/logout` — Đăng xuất, vô hiệu Token

* **Authentication:** Yêu cầu Bearer Token

**Response (204 No Content)**

### 2.4 `POST /auth/change-password` — Đổi mật khẩu

**Request Body:**

```json
{
  "current_password": "OldPassword@2025",
  "new_password": "NewPassword@2026"
}
```

**Response (200 OK):** Xác nhận thành công.

---

## 3. MODULE 2 — MASTER DATA

### 3.1 USERS & PERMISSIONS (UC-04)

#### 3.1.1 `GET /users` — Danh sách người dùng nội bộ

* **Phân quyền:** `ADMIN`
* **Query:** `page`, `page_size`, `keyword`, `role_code`, `branch_id`, `is_active`

#### 3.1.2 `POST /users` — Tạo tài khoản mới

* **Phân quyền:** `ADMIN`

**Request Body:**

```json
{
  "username": "minh.tt",
  "email": "minh.tt@company.com",
  "full_name": "Trần Thanh Minh",
  "phone": "0901234567",
  "branch_id": 1,
  "dept_id": 4,
  "role_id": 3,
  "send_welcome_email": true
}
```

**Response (201 Created):** Tài khoản tạo, mật khẩu tạm gửi qua email.

#### 3.1.3 `PUT /users/{user_id}` — Cập nhật thông tin / đổi vai trò

#### 3.1.4 `PATCH /users/{user_id}/deactivate` — Vô hiệu hóa tài khoản (Soft delete)

#### 3.1.5 `GET /roles` — Danh sách vai trò

#### 3.1.6 `GET /permissions` — Danh sách quyền hệ thống

#### 3.1.7 `PUT /roles/{role_id}/permissions` — Gán quyền cho vai trò

**Request Body:**

```json
{
  "permission_ids": [1, 2, 5, 7, 12]
}
```

### 3.2 MATERIALS (UC-02)

#### 3.2.1 `GET /materials/search` — Tìm vật tư bằng Full-Text Search Tiếng Việt

* **Phân quyền:** Tất cả người dùng nội bộ đã đăng nhập
* **Mô tả:** Sử dụng MSSQL Full-Text Index (Language code 1066 - Vietnamese), thay thế `LIKE '%keyword%'` để tăng tốc.

**Query Parameters:**

| Param | Kiểu | Mô tả |
| :--- | :--- | :--- |
| `keyword` | String | Chuỗi từ khóa (bắt buộc, tối thiểu 2 ký tự) |
| `category_id` | Integer | Lọc theo nhóm vật tư |
| `is_active` | Boolean | Mặc định `true` |
| `page`, `page_size` | Integer | Phân trang |

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "items": [
      {
        "material_id": 45,
        "material_code": "STEEL-HP-014",
        "material_name": "Thép hộp mạ kẽm Hòa Phát phi 14",
        "category_id": 1,
        "category_name": "Nguyên vật liệu",
        "uom": "Thanh",
        "min_stock_level": 50.00,
        "is_active": true
      }
    ],
    "pagination": { "page": 1, "page_size": 20, "total_items": 8, "total_pages": 1 }
  }
}
```

#### 3.2.2 `POST /materials` — Tạo vật tư mới (Master Data)

#### 3.2.3 `PUT /materials/{material_id}` — Cập nhật

#### 3.2.4 `PATCH /materials/{material_id}/deactivate` — Vô hiệu hóa (chuyển `is_active = 0`)

#### 3.2.5 `GET /material-categories` — Danh sách nhóm vật tư

### 3.3 SUPPLIERS (UC-03)

#### 3.3.1 `GET /suppliers` — Danh sách NCC

**Query:** `page`, `keyword`, `category_id`, `is_active`, `rating_min`, `rating_max`

#### 3.3.2 `POST /suppliers` — Tạo NCC mới

**Request Body:**

```json
{
  "supplier_code": "NCC-HP-001",
  "supplier_name": "Công ty Thép Hòa Phát",
  "tax_code": "0100123456",
  "contact_name": "Trần Văn A",
  "contact_email": "sales@hoaphat.com.vn",
  "contact_phone": "0241234567",
  "address": "Khu CN Phố Nối A, Hưng Yên"
}
```

**Response lỗi (409 Conflict) — Trùng MST:**

```json
{
  "success": false,
  "code": 409,
  "message": "Mã số thuế '0100123456' đã tồn tại trên hệ thống.",
  "errors": { "tax_code": ["Có thể trùng với NCC: 'Công ty Cổ phần Thép Hòa Phát Hà Nội'."] }
}
```

#### 3.3.3 `PUT /suppliers/{supplier_id}` — Cập nhật

#### 3.3.4 `GET /suppliers/{supplier_id}/profile` — Xem hồ sơ NCC chi tiết

Bao gồm: lịch sử order, đánh giá định kỳ (link UC-24), hợp đồng khung đính kèm, điểm `rating_score`.

#### 3.3.5 `POST /suppliers/{supplier_id}/contract-prices` — Thêm bảng giá thỏa thuận khung

**Request Body:**

```json
{
  "material_id": 45,
  "contract_unit_price": 245000.00,
  "valid_from": "2026-01-01",
  "valid_to": "2026-12-31",
  "contract_file_base64": "data:application/pdf;base64,JVBERi0xLjQ..."
}
```

#### 3.3.6 `GET /suppliers/{supplier_id}/contract-prices` — Danh sách bảng giá khung còn hiệu lực

### 3.4 BRANCHES & DEPARTMENTS

#### 3.4.1 `GET /branches` — Danh sách chi nhánh

#### 3.4.2 `GET /departments` — Danh sách phòng ban (hỗ trợ cây cha-con)

---

## 4. MODULE 3 — PURCHASE REQUEST (PR)

### 4.1 `POST /purchase-requests` — Tạo phiếu yêu cầu mua hàng

* **Phân quyền:** `DEPT_HEAD` (`PR_CREATE`)
* **Use Case:** UC-05 (PR thường), UC-05B (PR khẩn)

**Request Body — PR Thường:**

```json
{
  "priority_level": "NORMAL",
  "branch_id": 1,
  "dept_id": 7,
  "purpose": "Bổ sung thép hộp phục vụ bảo dưỡng dây chuyền CNC.",
  "items": [
    {
      "material_id": 45,
      "material_name_other": null,
      "qty_requested": 150.00,
      "uom": "Thanh",
      "estimated_unit_price": 250000.00,
      "required_deadline": "2026-06-15"
    },
    {
      "material_id": null,
      "material_name_other": "Đá mài hợp kim phi 120 đặc chủng",
      "qty_requested": 10.00,
      "uom": "Viên",
      "estimated_unit_price": 550000.00,
      "required_deadline": "2026-06-10"
    }
  ]
}
```

**Request Body — PR Khẩn (UC-05B):** Bổ sung 2 trường bắt buộc.

```json
{
  "priority_level": "URGENT",
  "branch_id": 1,
  "dept_id": 7,
  "urgent_reason": "Cháy thiết bị điều khiển PLC máy ép thủy lực số 3, dừng sản xuất hoàn toàn.",
  "urgency_impact": "Mất sản lượng ~2000 sản phẩm/ngày, ước thiệt hại 180tr/ngày.",
  "purpose": "Mua khẩn cấp PLC thay thế.",
  "items": [ /* ... */ ]
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "code": 201,
  "message": "Khởi tạo PR thành công.",
  "data": {
    "pr_id": 1024,
    "pr_code": "PR-20260526-008",
    "requester_user_id": 15,
    "priority_level": "NORMAL",
    "pr_status": "PENDING",
    "total_estimated_amount": 43000000.00,
    "created_at": "2026-05-26T08:35:00Z"
  }
}
```

**Response lỗi (422) — Vi phạm `CK_PRItems_MaterialCheck`:**

```json
{
  "success": false,
  "code": 422,
  "message": "Dữ liệu vi phạm ràng buộc loại trừ chéo vật tư.",
  "errors": {
    "items[1]": ["Phải điền 'material_id' (hàng chuẩn) HOẶC 'material_name_other' (hàng tự do), không được trống cả 2 và không được điền đồng thời cả 2."]
  }
}
```

**Response lỗi (422) — Vi phạm `CK_PR_UrgentFields`:**

```json
{
  "success": false,
  "code": 422,
  "message": "PR Khẩn bắt buộc cung cấp lý do và tác động vận hành.",
  "errors": {
    "urgent_reason": ["Trường này không được để trống khi 'priority_level' = 'URGENT'."],
    "urgency_impact": ["Trường này không được để trống khi 'priority_level' = 'URGENT'."]
  }
}
```

### 4.2 `GET /purchase-requests` — Danh sách PR

**Query:** `page`, `keyword`, `pr_status`, `priority_level`, `branch_id`, `dept_id`, `date_from`, `date_to`

> Quy tắc phân quyền theo RBAC: `DEPT_HEAD` chỉ thấy PR của phòng mình; `BUYER` thấy tất cả; `DIRECTOR` thấy tất cả + báo cáo tổng.

### 4.3 `GET /purchase-requests/{pr_id}` — Chi tiết PR

Trả về thông tin tổng + danh sách `PRItems` + tiến độ duyệt `DocumentApprovalProgress` + lịch sử trạng thái `PRStatusHistory`.

### 4.4 `PUT /purchase-requests/{pr_id}` — Chỉnh sửa PR (UC-06)

* **Điều kiện:** `pr_status = 'PENDING'`, người gọi là người tạo PR
* Body: như tạo mới (không cho đổi `priority_level` đã chốt)

### 4.5 `DELETE /purchase-requests/{pr_id}` — Hủy PR (UC-06)

* **Điều kiện:** `pr_status IN ('DRAFT', 'PENDING')`
* Hệ thống chuyển trạng thái sang `CANCELLED` (soft delete), ghi `PRStatusHistory` và `AuditLogs`.

**Request Body:**

```json
{ "cancel_reason": "Bộ phận đã có vật tư thay thế từ kho." }
```

### 4.6 `POST /purchase-requests/{pr_id}/approve` — Phê duyệt PR (UC-05, UC-05B)

* **Phân quyền:** Vai trò khớp với `ApprovalWorkflowSteps.role_id` của bước hiện hành

**Request Body:**

```json
{
  "action": "APPROVE",
  "comment": "Đã ký duyệt, số lượng khớp kế hoạch SX."
}
```

**Request Body (REJECT):**

```json
{
  "action": "REJECT",
  "comment": "Vượt ngân sách Q2, đề nghị tách nhỏ ra 2 đợt."
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "pr_id": 1024,
    "current_status": "APPROVED",
    "approval_progress": [
      { "step_sequence": 1, "role_code": "DEPT_HEAD", "status": "APPROVED", "approver_user_id": 8, "action_date": "2026-05-26T09:00:00Z" },
      { "step_sequence": 2, "role_code": "DIRECTOR", "status": "APPROVED", "approver_user_id": 2, "action_date": "2026-05-26T10:15:00Z" }
    ],
    "is_fully_approved": true
  }
}
```

### 4.7 `GET /purchase-requests/{pr_id}/status-history` — Lịch sử thay đổi trạng thái PR

### 4.8 `GET /purchase-requests/pending-my-approval` — DS PR đang chờ tài khoản hiện hành duyệt

Hữu ích cho dashboard cá nhân của Trưởng bộ phận / Giám đốc.

---

## 5. MODULE 4 — CART & ORDER

### 5.1 `POST /procurement-carts` — Tạo Cart và gom các dòng PR (UC-07)

* **Phân quyền:** `BUYER`

**Request Body:**

```json
{
  "cart_title": "Gom mua Thép xây dựng tháng 6/2026",
  "pr_items": [
    { "pr_item_id": 5012, "qty_in_cart": 150.00 },
    { "pr_item_id": 5015, "qty_in_cart": 80.00 },
    { "pr_item_id": 5021, "qty_in_cart": 200.00 }
  ]
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "code": 201,
  "data": {
    "cart_id": 312,
    "cart_title": "Gom mua Thép xây dựng tháng 6/2026",
    "buyer_user_id": 12,
    "items_count": 3,
    "created_at": "2026-05-26T10:30:00Z"
  }
}
```

### 5.2 `GET /procurement-carts` — Danh sách Cart của tài khoản hiện hành

### 5.3 `GET /procurement-carts/{cart_id}` — Chi tiết Cart kèm các `PRItems` liên kết

### 5.4 `PUT /procurement-carts/{cart_id}` — Chỉnh sửa Cart (UC-08)

**Request Body:** Hỗ trợ thêm/bớt `PRItems` và sửa `qty_in_cart`.

```json
{
  "cart_title": "Gom mua Thép xây dựng tháng 6/2026 (cập nhật)",
  "add_pr_items": [ { "pr_item_id": 5030, "qty_in_cart": 50.00 } ],
  "remove_pr_items": [ 5021 ],
  "update_pr_items": [ { "pr_item_id": 5012, "qty_in_cart": 200.00 } ]
}
```

> Hệ thống ghi log thay đổi tại `AuditLogs` và gửi thông báo tới Trưởng bộ phận nếu thay đổi số lượng.

### 5.5 `DELETE /procurement-carts/{cart_id}` — Hủy Cart (chỉ khi chưa convert)

### 5.6 `POST /procurement-carts/{cart_id}/convert-to-orders` — Chuyển Cart thành Order (UC-09)

**Request Body:** Tổng hợp theo vật tư, gán danh sách NCC mời chào giá.

```json
{
  "order_code_prefix": "ORD-20260526",
  "split_by_category": false,
  "order_items": [
    {
      "material_id": 45,
      "material_name_other": null,
      "qty_total_ordered": 430.00,
      "linked_pr_items": [
        { "pr_item_id": 5012, "qty_linked": 200.00 },
        { "pr_item_id": 5015, "qty_linked": 80.00 },
        { "pr_item_id": 5030, "qty_linked": 50.00 },
        { "pr_item_id": 5040, "qty_linked": 100.00 }
      ]
    }
  ],
  "supplier_ids": [14, 25, 31]
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "code": 201,
  "data": {
    "orders": [
      {
        "order_id": 501,
        "order_code": "ORD-20260526-001",
        "order_status": "DRAFT",
        "items_count": 1,
        "suppliers_invited_count": 3,
        "total_estimated_amount": 107500000.00
      }
    ]
  }
}
```

### 5.7 `GET /orders` — Danh sách Order

**Query:** `page`, `keyword`, `order_status`, `buyer_user_id`, `date_from`, `date_to`

### 5.8 `GET /orders/{order_id}` — Chi tiết Order

Trả về `OrderItems`, `OrderItemPRLinks`, `OrderSuppliers`, `QuotationRequests` đã phát hành, `IPOs` đã tạo.

### 5.9 `PUT /orders/{order_id}` — Chỉnh sửa Order (UC-09B) [BỔ SUNG v3.0]

* **Điều kiện:** `order_status IN ('DRAFT', 'QUOTING')` và chưa chốt IPO
* Cho phép: thêm/bớt NCC (chỉ khi NCC chưa submit báo giá), sửa thông tin liên hệ, sửa số lượng dòng (cảnh báo nếu vượt PR gốc)

**Request Body:**

```json
{
  "add_suppliers": [
    { "supplier_id": 47, "contact_override_email": "newcontact@supplier.com" }
  ],
  "remove_suppliers": [25],
  "update_items": [
    { "order_item_id": 1201, "qty_total_ordered": 500.00, "qty_change_reason": "Thêm 70 thanh do bộ phận C bổ sung yêu cầu khẩn." }
  ]
}
```

**Response lỗi (422) — NCC đã submit báo giá:**

```json
{
  "success": false,
  "code": 422,
  "message": "Không thể loại NCC đã submit báo giá. Vui lòng vô hiệu hóa báo giá thay vì xóa.",
  "errors": { "remove_suppliers[0]": ["NCC ID 25 đã submit báo giá tại quotation_id=854."] }
}
```

### 5.10 `DELETE /orders/{order_id}` — Hủy Order (chỉ khi chưa chốt IPO)

### 5.11 `PATCH /orders/{order_id}/status` — Cập nhật trạng thái giao hàng (UC-15)

* **Phân quyền:** `BUYER`

**Request Body:**

```json
{
  "new_status": "DELIVERING",
  "note": "Xe NCC đã xuất bến lúc 14h, dự kiến tới nhà máy 17h cùng ngày."
}
```

> Giá trị `new_status` cho sub-tracking giao hàng (lưu trong `OrderStatusHistory`): `WAITING_DELIVERY`, `DELIVERING`, `PARTIAL_DELIVERED`, `FULL_DELIVERED`, `CANCELLED`.

### 5.12 `GET /orders/{order_id}/status-history` — Lịch sử trạng thái Order

---

## 6. MODULE 5 — QUOTATION & VENDOR PORTAL

### 6.1 `POST /orders/{order_id}/invite-suppliers` — Gửi mời báo giá kèm Token bảo mật (UC-10)

* **Phân quyền:** `BUYER`
* **Mô tả:** Hệ thống sinh Token SHA-256, mã hóa một chiều, gửi email tới NCC

**Request Body:**

```json
{
  "supplier_ids": [14, 25, 31],
  "bidding_deadline": "2026-06-05T17:00:00Z",
  "email_template_code": "QUOTATION_INVITATION_VN",
  "custom_message": "Trân trọng kính mời quý NCC tham gia chào giá đợt thầu tháng 6/2026.",
  "min_suppliers_required_override": false
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "order_id": 501,
    "invitations": [
      {
        "supplier_id": 14,
        "supplier_name": "Công ty Thép Hòa Phát",
        "q_request_id": 9012,
        "secure_access_url": "https://vendor.company.com/portal/quote?token=8a3f9e2c1b7d4e6f0a5c8d2e...",
        "expires_at": "2026-06-05T17:00:00Z",
        "email_sent_at": "2026-05-26T11:00:00Z"
      }
    ]
  }
}
```

**Response lỗi (400) — Không đủ số NCC tối thiểu theo ngưỡng giá trị:**

```json
{
  "success": false,
  "code": 400,
  "message": "Tổng giá trị ước tính (75,000,000đ) vượt ngưỡng 50tr, yêu cầu tối thiểu 3 NCC.",
  "errors": {
    "supplier_ids": ["Hiện đang chọn 2 NCC, cần thêm tối thiểu 1 NCC. Liên hệ Trưởng phòng MH override nếu cần."]
  }
}
```

### 6.2 `POST /orders/{order_id}/resend-quotation` — Gửi nhắc nhở NCC chưa phản hồi [BỔ SUNG v3.0]

* **Phân quyền:** `BUYER`
* Không sinh Token mới, dùng lại Token cũ vẫn hợp lệ.

**Request Body:**

```json
{
  "supplier_ids": [25, 31],
  "remind_note": "Hạn báo giá còn 24h, vui lòng phản hồi sớm."
}
```

### 6.3 `POST /orders/{order_id}/manual-quotation` — Sinh link thủ công / Nhân viên MH nhập báo giá thay NCC

**Request Body:**

```json
{
  "supplier_id": 47,
  "manual_input": true,
  "items": [
    { "order_item_id": 1201, "quoted_unit_price": 248000.00, "supplier_note": "Báo giá nhận qua điện thoại 26/05" }
  ],
  "delivery_lead_time_days": 12,
  "payment_terms_note": "Công nợ 30 ngày kể từ ngày nhận đủ hàng."
}
```

### 6.4 `GET /vendor-portal/quotation-info?token={token}` — NCC xem thông tin yêu cầu báo giá (UC-11)

* **Authentication:** Không (xác thực qua Token URL)
* **Mô tả:** Trả về danh sách `order_items` để NCC điền giá. Không cần đăng nhập.

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "order_code": "ORD-20260526-001",
    "supplier_name": "Công ty Thép Hòa Phát",
    "bidding_deadline": "2026-06-05T17:00:00Z",
    "buyer_contact": { "name": "Nguyễn Văn Hoàng", "email": "buyer@company.com" },
    "items": [
      {
        "order_item_id": 1201,
        "material_name": "Thép hộp mạ kẽm phi 14",
        "qty_requested": 430.00,
        "uom": "Thanh",
        "delivery_to_branch": "CN Hà Nội"
      }
    ]
  }
}
```

**Response lỗi (410 Gone) — Token hết hạn / đã dùng:**

```json
{
  "success": false,
  "code": 410,
  "message": "Đường dẫn báo giá đã hết hiệu lực hoặc đã được sử dụng.",
  "errors": null
}
```

### 6.5 `POST /vendor-portal/submit-bid` — NCC nộp báo giá (UC-11)

* **Authentication:** Không (Token trong Body)
* **Mô tả:** Sau khi submit thành công, Token tự động `is_used = 1` để chặn re-use.

**Request Body:**

```json
{
  "secure_token": "8a3f9e2c1b7d4e6f0a5c8d2e...",
  "delivery_lead_time_days": 10,
  "payment_terms_note": "Net 30, không đặt cọc.",
  "supplier_note": "Cam kết chất lượng chuẩn TCVN, hỗ trợ bốc dỡ tận kho.",
  "items": [
    { "order_item_id": 1201, "quoted_unit_price": 242000.00, "supplier_note": "Hàng chính hãng, giấy CO/CQ đầy đủ." }
  ]
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "message": "Đã ghi nhận báo giá thành công.",
  "data": {
    "quotation_id": 954,
    "version": 1,
    "submitted_at": "2026-05-26T14:15:12Z",
    "total_quote_amount": 104060000.00
  }
}
```

### 6.6 `POST /vendor-portal/submit-bid-bulk` — Nộp báo giá hàng loạt qua file Excel [BỔ SUNG v3.0]

* **Authentication:** Không (Token trong body)
* **Mô tả:** Đáp ứng yêu cầu từ Meeting note: NCC có thể có hàng trăm dòng, cần submit qua Excel thay vì điền form từng dòng.

**Request:** `multipart/form-data` với `secure_token` (text) + `excel_file` (binary, định dạng .xlsx theo template hệ thống)

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "quotation_id": 955,
    "items_imported": 148,
    "items_failed": 2,
    "failed_rows": [
      { "row_index": 45, "error": "order_item_id 1245 không thuộc đơn hàng." },
      { "row_index": 67, "error": "quoted_unit_price phải > 0." }
    ]
  }
}
```

### 6.7 `GET /quotations/template.xlsx` — Tải template Excel báo giá

### 6.8 `GET /orders/{order_id}/quotations` — DS các báo giá NCC đã nộp cho Order

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "items": [
      {
        "quotation_id": 954,
        "supplier_id": 14,
        "supplier_name": "Công ty Thép Hòa Phát",
        "version": 1,
        "total_quote_amount": 104060000.00,
        "delivery_lead_time_days": 10,
        "submitted_at": "2026-05-26T14:15:12Z",
        "is_selected": false
      }
    ]
  }
}
```

### 6.9 `GET /quotations/{quotation_id}/versions` — Lịch sử phiên bản báo giá [BỔ SUNG v3.0]

> Phục vụ kiểm toán hoặc NCC submit nhiều lần (Meeting note đề cập).

### 6.10 `GET /orders/{order_id}/quotations/compare` — Bảng so sánh giá NCC (UC-12)

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "order_code": "ORD-20260526-001",
    "comparison": [
      {
        "order_item_id": 1201,
        "material_name": "Thép hộp mạ kẽm phi 14",
        "qty_required": 430.00,
        "contract_price_reference": 245000.00,
        "quotes": [
          { "supplier_id": 14, "supplier_name": "Hòa Phát", "quoted_unit_price": 242000.00, "lead_time_days": 10, "is_lowest": true },
          { "supplier_id": 25, "supplier_name": "Gang thép Thái Nguyên", "quoted_unit_price": 248000.00, "lead_time_days": 7 },
          { "supplier_id": 31, "supplier_name": "Pomina", "quoted_unit_price": 250000.00, "lead_time_days": 12 }
        ]
      }
    ]
  }
}
```

---

## 7. MODULE 6 — INTERNAL PO (IPO) ĐA PHIÊN BẢN

### 7.1 `POST /internal-purchase-orders` — Tạo IPO từ báo giá đã chọn (UC-12)

* **Phân quyền:** `BUYER`
* **Mô tả:** Tạo IPO mới `version = 1`, `is_latest = 1`, `ipo_status = 'DRAFT'`

**Request Body:**

```json
{
  "order_id": 501,
  "supplier_id": 14,
  "selected_items": [
    { "order_item_id": 1201, "quotation_item_id": 7012, "qty_final": 430.00, "unit_price_final": 242000.00 }
  ],
  "payment_terms_note": "Net 30, chuyển khoản ngân hàng Vietcombank.",
  "expected_delivery_date": "2026-06-15"
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "code": 201,
  "data": {
    "ipo_id": 302,
    "ipo_code": "IPO-202605-0014",
    "version": 1,
    "is_latest": true,
    "ipo_status": "DRAFT",
    "total_amount": 104060000.00,
    "supplier_name": "Công ty Thép Hòa Phát"
  }
}
```

### 7.2 `GET /internal-purchase-orders` — DS IPO

**Query:** `keyword`, `ipo_status`, `supplier_id`, `is_latest` (mặc định `true`), `date_from`, `date_to`

### 7.3 `GET /internal-purchase-orders/{ipo_id}` — Chi tiết một phiên bản IPO

### 7.4 `GET /internal-purchase-orders/by-code/{ipo_code}/versions` — Lịch sử tất cả phiên bản của 1 IPO

### 7.5 `POST /internal-purchase-orders/{ipo_id}/new-version` — Tạo phiên bản mới (UC-12B) [BỔ SUNG v3.0]

* **Điều kiện:** IPO hiện tại `ipo_status IN ('DRAFT', 'REJECTED')`
* **Quy tắc DB:** Hệ thống nhân bản IPO, hạ cờ `is_latest = 0` của bản cũ, tạo bản mới `version = old_version + 1`, `is_latest = 1`

**Request Body:**

```json
{
  "items": [
    { "order_item_id": 1201, "qty_final": 400.00, "unit_price_final": 240000.00 }
  ],
  "payment_terms_note": "Net 45 (đàm phán lại).",
  "change_reason": "Giảm 30 thanh do điều chỉnh kế hoạch SX; thương lượng giảm thêm 2000đ/thanh."
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "code": 201,
  "data": {
    "ipo_id": 305,
    "ipo_code": "IPO-202605-0014",
    "version": 2,
    "is_latest": true,
    "ipo_status": "DRAFT",
    "previous_version_id": 302
  }
}
```

### 7.6 `POST /internal-purchase-orders/{ipo_id}/submit-for-approval` — Submit duyệt

* **Điều kiện:** `ipo_status = 'DRAFT'`, chuyển sang `PENDING`
* Hệ thống đối chiếu `total_amount` với `ApprovalWorkflows` để sinh các bước duyệt

### 7.7 `POST /internal-purchase-orders/{ipo_id}/approve` — Phê duyệt IPO (UC-13) [BỔ SUNG v3.0]

* **Phân quyền:** Vai trò khớp với `ApprovalWorkflowSteps` của bước hiện hành (thường là `DIRECTOR`)

**Request Body:**

```json
{
  "action": "APPROVE",
  "comment": "Đã ký duyệt. Giá hợp lý so với hợp đồng khung."
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "ipo_id": 302,
    "ipo_status": "APPROVED",
    "approval_progress": [
      { "step_sequence": 1, "role_code": "PUR_MANAGER", "status": "APPROVED", "approver_user_id": 5 },
      { "step_sequence": 2, "role_code": "DIRECTOR", "status": "APPROVED", "approver_user_id": 2 }
    ],
    "approved_at": "2026-05-26T16:30:00Z"
  }
}
```

### 7.8 `GET /internal-purchase-orders/{ipo_id}/export-pdf` — Kết xuất file PDF IPO chính thức

Trả về file PDF (binary, `Content-Type: application/pdf`) với chữ ký số hoặc mã QR định danh phục vụ in ấn, ký tay.

### 7.9 `POST /internal-purchase-orders/{ipo_id}/upload-signed-pdf` — Upload PDF đã ký scan

**Request:** `multipart/form-data` với `signed_pdf_file` (binary).

**Response (200 OK):** Cập nhật `signed_pdf_path`.

### 7.10 `GET /internal-purchase-orders/pending-my-approval` — DS IPO chờ duyệt của tài khoản hiện hành

### 7.11 `PATCH /internal-purchase-orders/{ipo_id}/mark-executing` — Trưởng phòng MH đánh dấu đã liên hệ NCC (UC-14)

> Sau khi APPROVED, Trưởng phòng MH liên hệ NCC ngoài hệ thống và đánh dấu bước này để theo dõi.

---

## 8. MODULE 7 — WAREHOUSE

### 8.1 `POST /inventory/receipts` — Lập phiếu nhập kho + IQC (UC-16)

* **Phân quyền:** `WAREHOUSE_KEEPER`
* **Mô tả:** Thực hiện cân đo, phân loại đạt/lỗi. Đáp ứng `CK_StockReceiptItems_QtyLogic` (`qty_received = qty_passed + qty_failed`).

**Request Body:**

```json
{
  "ipo_id": 302,
  "delivery_note_ref": "BB-DELIVERY-HP-9981",
  "received_at": "2026-05-30T10:00:00Z",
  "warehouse_branch_id": 1,
  "note": "Xe tải số 29H-12345, tài xế Trần Văn B.",
  "items": [
    {
      "ipo_item_id": 3501,
      "material_id": 45,
      "material_name_other": null,
      "qty_ordered": 430.00,
      "qty_received": 430.00,
      "qty_passed": 428.00,
      "qty_failed": 2.00,
      "qc_fail_reason": "02 thanh móp méo, cong vênh do va đập khi vận chuyển.",
      "photo_paths": [
        "/storage/qc-photos/2026/05/30/ipo302_item3501_001.jpg",
        "/storage/qc-photos/2026/05/30/ipo302_item3501_002.jpg"
      ]
    }
  ]
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "code": 201,
  "message": "Đã ghi nhận phiếu nhập kho IQC, số lượng đạt chuẩn đã cộng vào tồn kho khả dụng.",
  "data": {
    "receipt_id": 844,
    "receipt_code": "RE-20260530-092",
    "associated_ipo_code": "IPO-202605-0014",
    "stock_updated_items": [
      { "material_id": 45, "branch_id": 1, "qty_added_to_on_hand": 430.00, "qty_added_to_available": 428.00, "qty_added_to_quarantine": 2.00 }
    ]
  }
}
```

**Response lỗi (422) — Vi phạm phương trình cân bằng IQC:**

```json
{
  "success": false,
  "code": 422,
  "message": "Vi phạm phương trình cân bằng kiểm định: qty_received phải bằng (qty_passed + qty_failed).",
  "errors": {
    "items[0]": ["qty_received (430) ≠ qty_passed (425) + qty_failed (2) = 427."]
  }
}
```

**Response lỗi (422) — Thiếu ảnh minh chứng khi có hàng lỗi:**

```json
{
  "success": false,
  "code": 422,
  "message": "Phải đính kèm ảnh minh chứng khi qty_failed > 0.",
  "errors": {
    "items[0].photo_paths": ["Trường này không được trống khi qty_failed > 0 (CK_StockReceiptItems_PhotoMandatory)."]
  }
}
```

**Response lỗi (422) — Vượt khối lượng còn lại của IPO:**

```json
{
  "success": false,
  "code": 422,
  "message": "Số lượng tiếp nhận vượt hạn mức cho phép của IPO.",
  "errors": {
    "items[0].qty_received": ["Tiếp nhận 435 vượt khối lượng còn lại được phép nhập kho theo IPO (Tối đa: 430, đã nhập trước đó: 0)."]
  }
}
```

### 8.2 `POST /inventory/receipts/{receipt_id}/upload-photo` — Upload ảnh QC riêng

**Request:** `multipart/form-data` với 1 hoặc nhiều file ảnh. Trả về đường dẫn để gán vào `photo_paths` của receipt items.

### 8.3 `GET /inventory/receipts` — DS phiếu nhập kho

### 8.4 `GET /inventory/receipts/{receipt_id}` — Chi tiết phiếu nhập kho

### 8.5 `POST /inventory/issues` — Lập phiếu xuất kho cấp phát bộ phận (UC-16B) [BỔ SUNG v3.0]

* **Phân quyền:** `WAREHOUSE_KEEPER`

**Request Body:**

```json
{
  "pr_id": 1024,
  "dept_id": 7,
  "receiver_user_id": 18,
  "issue_at": "2026-06-01T09:00:00Z",
  "items": [
    { "material_id": 45, "qty_issued": 150.00 }
  ],
  "note": "Cấp phát đợt 1 cho xưởng cơ khí."
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "code": 201,
  "data": {
    "issue_id": 220,
    "issue_code": "IS-20260601-015",
    "stock_updated": [
      { "material_id": 45, "branch_id": 1, "qty_decreased_from_available": 150.00 }
    ]
  }
}
```

**Response lỗi (422) — Vượt tồn khả dụng:**

```json
{
  "success": false,
  "code": 422,
  "message": "Số lượng xuất vượt tồn kho khả dụng.",
  "errors": { "items[0].qty_issued": ["Yêu cầu xuất 150, tồn khả dụng chỉ còn 128."] }
}
```

### 8.6 `GET /inventory/issues` — DS phiếu xuất kho

### 8.7 `POST /inventory/issues/{issue_id}/confirm-receipt` — Trưởng bộ phận xác nhận nhận hàng + chấm sao chất lượng (UC-17) [BỔ SUNG v3.0]

* **Phân quyền:** `DEPT_HEAD`

**Request Body:**

```json
{
  "items_quality_rating": [
    { "issue_item_id": 7012, "quality_rating": 4, "comment": "Hàng tốt, có 1 thanh hơi xước nhẹ không ảnh hưởng." }
  ],
  "overall_status": "ACCEPTED"
}
```

> Giá trị `overall_status`: `ACCEPTED`, `PARTIALLY_ACCEPTED`, `REJECTED`. Nếu `REJECTED` → tạo phiếu hoàn trả NCC (UC-16C). `quality_rating` lưu vào `StockIssueItems` phục vụ UC-24.

### 8.8 `POST /inventory/return-orders` — Lập phiếu hoàn trả NCC (UC-16C) [BỔ SUNG v3.0]

* **Phân quyền:** `WAREHOUSE_KEEPER` hoặc `BUYER`

**Request Body:**

```json
{
  "supplier_id": 14,
  "receipt_id": 844,
  "reason_category": "QUALITY_DEFECT",
  "items": [
    { "material_id": 45, "qty_returned": 2.00, "reason": "Móp méo, cong vênh, không sử dụng được." }
  ],
  "evidence_photo_paths": ["/storage/qc-photos/2026/05/30/ipo302_item3501_001.jpg"],
  "notify_supplier_email": true
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "code": 201,
  "data": {
    "return_id": 88,
    "return_code": "RT-20260601-005",
    "return_status": "DRAFT",
    "stock_decreased_from_quarantine": [
      { "material_id": 45, "branch_id": 1, "qty_decreased": 2.00 }
    ]
  }
}
```

> Giá trị `reason_category`: `QUALITY_DEFECT`, `WRONG_SPEC`, `EXCESS_QUANTITY`, `OTHER`.

### 8.9 `PATCH /inventory/return-orders/{return_id}/status` — Cập nhật trạng thái phiếu trả

**Request Body:**

```json
{
  "new_status": "SENT",
  "note": "Đã giao xe trả về kho NCC, có biên bản ký nhận của tài xế.",
  "tracking_ref": "VN-EXPRESS-9988-77"
}
```

> Luồng trạng thái: `DRAFT` → `SENT` → `RESOLVED`.

### 8.10 `GET /inventory/return-orders` — DS phiếu hoàn trả

### 8.11 `GET /inventory/stock` — Truy vấn tồn kho theo chi nhánh / vật tư [BỔ SUNG v3.0]

**Query:** `branch_id`, `material_id`, `category_id`, `low_stock_only` (boolean), `page`, `page_size`

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "items": [
      {
        "branch_id": 1,
        "branch_name": "CN Hà Nội",
        "material_id": 45,
        "material_code": "STEEL-HP-014",
        "material_name": "Thép hộp mạ kẽm phi 14",
        "qty_on_hand": 278.00,
        "qty_available": 276.00,
        "qty_quarantine": 2.00,
        "min_stock_level": 50.00,
        "low_stock_warning": false,
        "last_updated_at": "2026-05-30T10:00:00Z"
      }
    ]
  }
}
```

### 8.12 `GET /inventory/stock/{material_id}/movement-history` — Lịch sử biến động tồn kho (FIFO truy vết) [BỔ SUNG v3.0]

---

## 9. MODULE 8 — INVOICE, 3-WAY MATCHING, PAYMENT, CREDIT/DEBIT NOTE

### 9.1 `POST /invoices` — Nhập hóa đơn từ NCC (UC-18) [BỔ SUNG v3.0]

* **Phân quyền:** `BUYER` hoặc `ACCOUNTANT`

**Request Body:**

```json
{
  "ipo_id": 302,
  "supplier_id": 14,
  "invoice_number": "0025146",
  "invoice_serial": "1C26TAA",
  "invoice_date": "2026-05-31",
  "amount_before_tax": 103580000.00,
  "tax_amount": 10358000.00,
  "total_amount": 113938000.00,
  "invoice_pdf_base64": "data:application/pdf;base64,JVBERi0xLjQK..."
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "code": 201,
  "data": {
    "invoice_id": 412,
    "invoice_number": "0025146",
    "matching_status": "PENDING",
    "created_at": "2026-05-31T16:00:00Z"
  }
}
```

**Response lỗi (422) — Vi phạm phương trình kế toán:**

```json
{
  "success": false,
  "code": 422,
  "message": "Vi phạm phương trình kế toán: total_amount phải = amount_before_tax + tax_amount.",
  "errors": { "total_amount": ["113.940.000 ≠ 103.580.000 + 10.358.000 = 113.938.000."] }
}
```

### 9.2 `POST /invoices/{invoice_id}/run-matching` — Kích hoạt thuật toán đối soát 3 chiều (UC-23)

* **Phân quyền:** `ACCOUNTANT` (hoặc tự động trigger ngay sau khi nhập invoice)
* **Mô tả:** So khớp `IPOItems.qty_final` vs `StockReceiptItems.qty_passed` vs `Invoices.qty_invoice`; tính `qty_diff`, `price_diff`; áp ngưỡng từ `SystemConfigs`.

**Response (200 OK — Kết quả MATCHED):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "invoice_id": 412,
    "matching_status": "MATCHED",
    "discrepancy_detected": false,
    "summary": {
      "ipo_total_qty": 430.00,
      "iqc_total_passed_qty": 428.00,
      "invoice_total_qty": 428.00,
      "total_price_variance": 0.00
    },
    "matching_details": [
      {
        "matching_id": 1501,
        "ipo_item_id": 3501,
        "receipt_item_id": 9012,
        "qty_invoice": 428.00,
        "qty_received_passed": 428.00,
        "price_invoice": 242000.00,
        "price_ipo": 242000.00,
        "qty_diff": 0.00,
        "price_diff": 0.00,
        "is_error": false
      }
    ],
    "action_recommended": "READY_FOR_PAYMENT"
  }
}
```

**Response (200 OK — Kết quả MISMATCHED):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "invoice_id": 413,
    "matching_status": "MISMATCHED",
    "discrepancy_detected": true,
    "summary": {
      "ipo_total_qty": 430.00,
      "iqc_total_passed_qty": 428.00,
      "invoice_total_qty": 430.00,
      "total_price_variance": 484000.00
    },
    "matching_details": [
      {
        "matching_id": 1502,
        "ipo_item_id": 3501,
        "qty_invoice": 430.00,
        "qty_received_passed": 428.00,
        "qty_diff": 2.00,
        "price_invoice": 242000.00,
        "price_ipo": 242000.00,
        "price_diff": 0.00,
        "is_error": true,
        "error_type": "QUANTITY_OVER_IQC",
        "error_description": "Số lượng đòi tiền (430) vượt quá số lượng kiểm định đạt chuẩn thực tế (428)."
      }
    ],
    "action_recommended": "REJECT_INVOICE_OR_REQUEST_CORRECTION_OR_OVERRIDE"
  }
}
```

### 9.3 `POST /invoices/{invoice_id}/override-matching` — Ban Giám đốc ghi đè lỗi đối soát (UC-23)

* **Phân quyền:** Chỉ `DIRECTOR`
* **Mô tả:** Khi MISMATCHED không thể yêu cầu NCC điều chỉnh hóa đơn, GĐ có thể override để tiếp tục thanh toán. Ghi `AuditLogs` với `event_type = 'OVERRIDE_MATCH'`.

**Request Body:**

```json
{
  "override_note": "Chấp thuận thanh toán theo invoice. 02 thanh thép lỗi sẽ trừ vào đợt giao hàng tiếp theo theo thỏa thuận miệng với GĐ Hòa Phát."
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "invoice_id": 413,
    "is_overridden": true,
    "override_by_user_id": 2,
    "override_at": "2026-05-31T17:30:00Z",
    "matching_status": "MISMATCHED",
    "ready_for_payment": true
  }
}
```

### 9.4 `GET /invoices` — DS hóa đơn

**Query:** `page`, `matching_status`, `supplier_id`, `is_overridden`, `date_from`, `date_to`

### 9.5 `GET /invoices/{invoice_id}` — Chi tiết hóa đơn + kết quả đối soát

### 9.6 `POST /payment-requests` — Tạo yêu cầu thanh toán (UC-19) [BỔ SUNG v3.0]

* **Phân quyền:** `BUYER`
* **Điều kiện:** Invoice phải `MATCHED` hoặc `is_overridden = true`

**Request Body:**

```json
{
  "invoice_id": 412,
  "requested_amount": 113938000.00,
  "payment_deadline": "2026-06-30",
  "payment_method": "BANK_TRANSFER",
  "note": "Thanh toán theo điều khoản Net 30 của IPO-202605-0014."
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "code": 201,
  "data": {
    "payment_req_id": 720,
    "payment_req_code": "PAY-20260601-018",
    "req_status": "PENDING"
  }
}
```

### 9.7 `GET /payment-requests` — DS yêu cầu thanh toán

### 9.8 `POST /payment-requests/{payment_req_id}/process` — Kế toán xử lý thanh toán (UC-20) [BỔ SUNG v3.0]

* **Phân quyền:** `ACCOUNTANT`

**Request Body:**

```json
{
  "action": "PAID",
  "actual_paid_amount": 113938000.00,
  "paid_at": "2026-06-15T14:30:00Z",
  "transaction_ref": "VCB-2026-0615-9988",
  "note": "Đã chuyển khoản Vietcombank, biên lai đính kèm."
}
```

> Giá trị `action`: `APPROVE` (duyệt chờ thanh toán), `PAID` (đã thanh toán xong), `REJECT` (từ chối).

### 9.9 `POST /credit-notes` — Tạo Credit Note (giảm trừ công nợ NCC) [BỔ SUNG v3.0]

* **Phân quyền:** `ACCOUNTANT`
* **Use Case:** UC-16C, UC-20 (khảo sát 6.5)

**Request Body:**

```json
{
  "supplier_id": 14,
  "invoice_id": 412,
  "return_id": 88,
  "credit_amount": 484000.00,
  "credit_date": "2026-06-05",
  "credit_note_number": "CN-2026-0014",
  "reason": "Hoàn trả 2 thanh thép lỗi, giảm trừ vào kỳ thanh toán tới.",
  "credit_pdf_base64": "data:application/pdf;base64,JVBERi0xLjQ..."
}
```

**Response (201 Created):** Trả về `credit_note_id`, liên kết với invoice/payment để tự động giảm trừ.

### 9.10 `POST /debit-notes` — Tạo Debit Note (NCC điều chỉnh giảm giá) [BỔ SUNG v3.0]

**Request Body:**

```json
{
  "supplier_id": 14,
  "invoice_id": 412,
  "debit_amount": 200000.00,
  "debit_date": "2026-06-10",
  "debit_note_number": "DN-2026-0008",
  "reason": "NCC giảm giá đợt khuyến mại đầu tháng 6.",
  "debit_pdf_base64": "data:application/pdf;base64,JVBERi0xLjQ..."
}
```

### 9.11 `GET /credit-notes`, `GET /debit-notes` — DS Credit/Debit Note

---

## 10. MODULE 9 — REPORTING, EXPORT KẾ TOÁN, ĐÁNH GIÁ NCC, AUDIT LOG, CẤU HÌNH

### 10.1 REPORTING & DASHBOARD (UC-21) [BỔ SUNG v3.0]

#### 10.1.1 `GET /reports/po-status` — Báo cáo tình trạng PO

**Query:** `date_from`, `date_to`, `branch_id`, `dept_id`, `supplier_id`, `format` (`json`/`xlsx`/`pdf`)

#### 10.1.2 `GET /reports/supplier-performance` — Hiệu suất NCC theo kỳ

#### 10.1.3 `GET /reports/cost-by-category` — Chi phí mua theo danh mục

#### 10.1.4 `GET /reports/payables-aging` — Công nợ phải trả theo độ tuổi

#### 10.1.5 `GET /reports/inventory-by-branch` — Tồn kho theo chi nhánh

#### 10.1.6 `GET /reports/urgent-pr-summary` — Báo cáo PR khẩn định kỳ (phục vụ hậu kiểm)

#### 10.1.7 `GET /reports/dashboard-summary` — Dashboard tổng cho GĐ

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "kpi": {
      "open_prs": 23,
      "pending_approvals": 8,
      "ipos_in_progress": 15,
      "overdue_payments": 2,
      "low_stock_items": 7
    },
    "charts": {
      "monthly_spending": [/* ... */],
      "supplier_distribution": [/* ... */]
    }
  }
}
```

### 10.2 EXPORT KẾ TOÁN (UC-22) [BỔ SUNG v3.0]

#### 10.2.1 `GET /accounting/export-templates` — DS template export hỗ trợ

**Response:** `["MISA_SME_2025", "FAST_ACCOUNTING_11", "EXCEL_STANDARD", "CUSTOM_FORMAT_01"]`

#### 10.2.2 `POST /accounting/exports` — Xuất file dữ liệu kế toán

**Request Body:**

```json
{
  "template_code": "MISA_SME_2025",
  "data_type": "INVOICES_AND_PAYMENTS",
  "date_from": "2026-05-01",
  "date_to": "2026-05-31",
  "branch_id": 1,
  "supplier_id": null,
  "include_already_exported": false
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "export_id": 145,
    "file_url": "/storage/exports/MISA_SME_2025_202605_145.xlsx",
    "file_format": "xlsx",
    "rows_exported": 42,
    "expires_at": "2026-06-26T08:30:00Z"
  }
}
```

> Giá trị `data_type`: `INVOICES_ONLY`, `PAYMENTS_ONLY`, `INVOICES_AND_PAYMENTS`, `CREDIT_DEBIT_NOTES`, `ALL`.

#### 10.2.3 `GET /accounting/exports` — Lịch sử các lần export (tránh export trùng)

#### 10.2.4 `POST /accounting/exports/{export_id}/re-export` — Xuất lại kỳ cũ (ghi audit log)

### 10.3 ĐÁNH GIÁ NCC (UC-24) [BỔ SUNG v3.0]

#### 10.3.1 `POST /supplier-evaluations` — Tạo đánh giá định kỳ

* **Phân quyền:** `PUR_MANAGER`

**Request Body:**

```json
{
  "supplier_id": 14,
  "period_type": "QUARTER",
  "period_value": "2026-Q2",
  "scores": {
    "delivery_on_time": 85,
    "quality_average": 88,
    "price_competitiveness": 75,
    "responsiveness": 90,
    "subjective_score": 80
  },
  "weights": {
    "delivery_on_time": 0.30,
    "quality_average": 0.30,
    "price_competitiveness": 0.20,
    "responsiveness": 0.10,
    "subjective_score": 0.10
  },
  "comment": "NCC ổn định, giá hơi cao so với mặt bằng."
}
```

**Response (201 Created):**

```json
{
  "success": true,
  "code": 201,
  "data": {
    "evaluation_id": 56,
    "supplier_id": 14,
    "period_value": "2026-Q2",
    "total_score": 83.50,
    "rank": "SILVER",
    "evaluator_user_id": 5,
    "created_at": "2026-06-30T16:00:00Z"
  }
}
```

> Quy ước `rank` (cấu hình tại `SystemConfigs`): `GOLD ≥ 85`, `SILVER 70-84`, `BRONZE 50-69`, `WARNING < 50`.

#### 10.3.2 `GET /suppliers/{supplier_id}/evaluations` — Lịch sử đánh giá của 1 NCC

#### 10.3.3 `GET /supplier-evaluations/auto-aggregate?supplier_id={id}&period={period}` — Tự động tổng hợp các chỉ số (chưa lưu)

> Hỗ trợ Trưởng phòng MH xem trước số liệu trước khi tạo bản đánh giá chính thức.

### 10.4 AUDIT LOG (UC-25) [GIỮ TỪ v2.0, MỞ RỘNG]

#### 10.4.1 `GET /system/audit-logs` — Tra cứu nhật ký thao tác

* **Phân quyền:** `ADMIN` (đầy đủ), `DIRECTOR` (báo cáo tổng)

**Query:**

| Param | Mô tả |
| :--- | :--- |
| `object_type` | `PurchaseRequisitions`, `IPOs`, `Invoices`, `Inventory`, ... |
| `object_id` | ID bản ghi |
| `event_type` | `INSERT`, `UPDATE`, `DELETE`, `OVERRIDE_MATCH`, `BYPASS_PR` |
| `user_id` | Lọc theo người thao tác |
| `date_from`, `date_to` | Khoảng thời gian |
| `page`, `page_size` | Phân trang |

**Response (200 OK):**

```json
{
  "success": true,
  "code": 200,
  "data": {
    "items": [
      {
        "audit_id": 15402,
        "event_type": "UPDATE",
        "object_type": "IPOs",
        "object_id": "302",
        "user_id": 12,
        "username": "hoang.nv",
        "ip_address": "192.168.1.45",
        "old_values": { "ipo_status": "DRAFT" },
        "new_values": { "ipo_status": "PENDING" },
        "created_at": "2026-05-26T16:55:00Z"
      }
    ],
    "pagination": { "page": 1, "page_size": 20, "total_items": 158, "total_pages": 8 }
  }
}
```

#### 10.4.2 `GET /system/audit-logs/export` — Xuất file Excel/CSV audit log phục vụ kiểm toán

### 10.5 SYSTEM CONFIGS [BỔ SUNG v3.0]

#### 10.5.1 `GET /system/configs` — DS tham số cấu hình

#### 10.5.2 `GET /system/configs/{config_key}` — Lấy giá trị 1 tham số

#### 10.5.3 `PUT /system/configs/{config_key}` — Cập nhật tham số

* **Phân quyền:** `ADMIN`

**Request Body:**

```json
{
  "config_value_json": {
    "min_suppliers_thresholds": [
      { "amount_from": 0, "amount_to": 5000000, "min_suppliers": 1 },
      { "amount_from": 5000000, "amount_to": 50000000, "min_suppliers": 2 },
      { "amount_from": 50000000, "amount_to": null, "min_suppliers": 3 }
    ]
  },
  "description": "Ngưỡng số NCC tối thiểu theo giá trị order."
}
```

**Các config_key chuẩn:**

| Config Key | Mô tả |
| :--- | :--- |
| `MIN_SUPPLIERS_THRESHOLDS` | Ngưỡng số NCC tối thiểu khi mời thầu |
| `URGENT_PR_MAX_AMOUNT` | Ngưỡng giá trị tối đa cho PR Khẩn |
| `URGENT_PR_ALERT_ROLES` | Danh sách vai trò nhận alert PR Khẩn |
| `MATCHING_TOLERANCE_PERCENT` | Biên độ chấp nhận chênh lệch đối soát 3 chiều (%) |
| `MATCHING_TOLERANCE_AMOUNT` | Biên độ chấp nhận chênh lệch tuyệt đối (đồng) |
| `LOGIN_LOCK_THRESHOLD` | Số lần đăng nhập sai trước khi khóa (mặc định 5) |
| `LOGIN_LOCK_DURATION_MINUTES` | Thời gian khóa (mặc định 30) |
| `SUPPLIER_RANK_THRESHOLDS` | Ngưỡng xếp hạng GOLD/SILVER/BRONZE/WARNING |
| `EVALUATION_WEIGHTS_DEFAULT` | Trọng số mặc định khi đánh giá NCC |
| `EMAIL_QUOTATION_TEMPLATE` | Template email mời báo giá |

### 10.6 NOTIFICATIONS [BỔ SUNG v3.0]

#### 10.6.1 `GET /notifications` — DS thông báo của user hiện hành

**Query:** `is_read`, `notification_type`, `page`, `page_size`

#### 10.6.2 `PATCH /notifications/{notification_id}/mark-read` — Đánh dấu đã đọc

#### 10.6.3 `POST /notifications/mark-all-read` — Đánh dấu tất cả đã đọc

#### 10.6.4 `GET /notifications/unread-count` — Số thông báo chưa đọc (cho badge UI)

---

## 11. PHỤ LỤC

### 11.1 Bảng đối chiếu Use-Case ↔ API Endpoint

| UC | Tên Use-Case | Endpoint chính |
| :--- | :--- | :--- |
| UC-01 | Đăng nhập | `POST /auth/login` |
| UC-02 | Quản lý vật tư | `GET/POST/PUT /materials*`, `GET /materials/search` |
| UC-03 | Quản lý NCC | `GET/POST/PUT /suppliers*`, `/contract-prices` |
| UC-04 | Quản lý user & phân quyền | `/users`, `/roles`, `/permissions` |
| UC-05 | Tạo PR thường | `POST /purchase-requests` (`priority_level=NORMAL`) |
| UC-05B | Tạo PR khẩn | `POST /purchase-requests` (`priority_level=URGENT`) |
| UC-06 | Sửa/Hủy PR | `PUT /purchase-requests/{id}`, `DELETE` |
| UC-07 | Tạo Cart | `POST /procurement-carts` |
| UC-08 | Sửa Cart | `PUT /procurement-carts/{id}` |
| UC-09 | Tạo Order, chọn NCC | `POST /procurement-carts/{id}/convert-to-orders` |
| UC-09B | Sửa Order | `PUT /orders/{id}` |
| UC-10 | Gửi mời báo giá | `POST /orders/{id}/invite-suppliers`, `/resend-quotation` |
| UC-11 | NCC nộp báo giá | `POST /vendor-portal/submit-bid`, `/submit-bid-bulk`, `GET /vendor-portal/quotation-info` |
| UC-12 | So sánh & chốt giá / Xuất IPO | `GET /orders/{order_id}/quotations/compare`, `POST /internal-purchase-orders` |
| UC-12B | Sửa IPO sau từ chối | `POST /internal-purchase-orders/{id}/new-version` |
| UC-13 | Phê duyệt IPO | `POST /internal-purchase-orders/{id}/approve` |
| UC-14 | Thực hiện mua sau duyệt | `PATCH /internal-purchase-orders/{id}/mark-executing` |
| UC-15 | Cập nhật trạng thái đơn | `PATCH /orders/{id}/status` |
| UC-16 | Nhập kho IQC | `POST /inventory/receipts` |
| UC-16B | Xuất kho cho bộ phận | `POST /inventory/issues` |
| UC-16C | Hoàn trả NCC | `POST /inventory/return-orders` |
| UC-17 | Xác nhận nhận hàng + đánh giá | `POST /inventory/issues/{id}/confirm-receipt` |
| UC-18 | Nhập hóa đơn | `POST /invoices` |
| UC-19 | Tạo yêu cầu thanh toán | `POST /payment-requests` |
| UC-20 | Xử lý thanh toán | `POST /payment-requests/{id}/process`, `/credit-notes`, `/debit-notes` |
| UC-21 | Báo cáo & thống kê | `GET /reports/*` |
| UC-22 | Export kế toán | `POST /accounting/exports`, `GET /accounting/export-templates` |
| UC-23 | Đối soát 3 chiều | `POST /invoices/{id}/run-matching`, `/override-matching` |
| UC-24 | Đánh giá NCC | `POST /supplier-evaluations`, `GET /suppliers/{id}/evaluations` |
| UC-25 | Audit log | `GET /system/audit-logs`, `/export` |

### 11.2 Chính sách Rate Limit

| Loại endpoint | Quota |
| :--- | :--- |
| `POST /auth/login` | 10 req/phút/IP |
| `POST /vendor-portal/*` | 20 req/phút/token |
| API thông thường (có JWT) | 600 req/phút/user |
| `GET /reports/*`, `POST /accounting/exports` | 30 req/phút/user |

### 11.3 Lịch sử thay đổi so với API Document v2.0

| Loại | Thay đổi | Lý do |
| :--- | :--- | :--- |
| **SỬA** | Enum `priority` đổi `HIGH` → `URGENT` | Khớp DB CHECK `CK_PR_Priority` |
| **SỬA** | Enum `matching_status` đổi `DISCREPANCY` → `MISMATCHED` | Khớp DB CHECK trên `Invoices` |
| **SỬA** | Bỏ `DRAFT_PENDING_SCAN`, `ORDERED` ở IPO | Khớp DB CHECK `CK_IPOs_Status` |
| **SỬA** | Thời gian khóa tài khoản: 30 phút (khớp URD §4.1) | Đồng bộ với URD; bỏ con số 15 phút của SRS v2.0 |
| **SỬA** | Phương trình IQC = `qty_received = qty_passed + qty_failed` | Khớp DB `CK_StockReceiptItems_QtyLogic` |
| **SỬA** | `photo_paths` chuyển từ `photo_evidence_base64` sang mảng đường dẫn JSON | Khớp DB column type `NVARCHAR(MAX)` chứa JSON array |
| **BỔ SUNG** | 6 endpoint quản lý User/Role/Permission | Phủ UC-04 còn thiếu |
| **BỔ SUNG** | 4 endpoint quản lý NCC + hợp đồng khung | Phủ UC-03 còn thiếu |
| **BỔ SUNG** | `PUT/DELETE /purchase-requests/{id}` | Phủ UC-06 còn thiếu |
| **BỔ SUNG** | `PUT /procurement-carts/{id}` | Phủ UC-08 còn thiếu |
| **BỔ SUNG** | `PUT /orders/{id}`, `PATCH /orders/{id}/status` | Phủ UC-09B, UC-15 còn thiếu |
| **BỔ SUNG** | `POST /vendor-portal/submit-bid-bulk` | Đáp ứng Meeting note: hàng trăm dòng qua Excel |
| **BỔ SUNG** | `POST /orders/{id}/resend-quotation`, `/manual-quotation` | Đáp ứng UC-10 luồng thay thế |
| **BỔ SUNG** | `GET /quotations/{id}/versions` | Phủ UC-11 lưu lịch sử nộp báo giá |
| **BỔ SUNG** | `GET /orders/{id}/quotations/compare` | Phủ UC-12 màn so sánh |
| **BỔ SUNG** | `POST /internal-purchase-orders/{id}/new-version` | Phủ UC-12B còn thiếu |
| **BỔ SUNG** | `POST /internal-purchase-orders/{id}/approve` | Phủ UC-13 còn thiếu |
| **BỔ SUNG** | `POST /inventory/issues`, `/confirm-receipt` | Phủ UC-16B, UC-17 còn thiếu |
| **BỔ SUNG** | `POST /inventory/return-orders` + status | Phủ UC-16C còn thiếu |
| **BỔ SUNG** | `GET /inventory/stock`, `/movement-history` | Cho dashboard và báo cáo tồn kho |
| **BỔ SUNG** | `POST /invoices` riêng | Phủ UC-18 (v2.0 gộp vào endpoint matching) |
| **BỔ SUNG** | `POST /invoices/{id}/override-matching` | Phủ UC-23 luồng GĐ override |
| **BỔ SUNG** | `POST /payment-requests`, `/process` | Phủ UC-19, UC-20 còn thiếu |
| **BỔ SUNG** | `POST /credit-notes`, `/debit-notes` | Đáp ứng khảo sát 6.5 |
| **BỔ SUNG** | 7 endpoint Reporting `/reports/*` | Phủ UC-21 còn thiếu |
| **BỔ SUNG** | 4 endpoint Export kế toán `/accounting/*` | Phủ UC-22 còn thiếu (yêu cầu từ Meeting note) |
| **BỔ SUNG** | 3 endpoint Đánh giá NCC `/supplier-evaluations` | Phủ UC-24 còn thiếu |
| **BỔ SUNG** | 4 endpoint Notifications | Hỗ trợ in-app notification của UC-05B, UC-10, UC-13 |
| **BỔ SUNG** | 3 endpoint System Configs | Lưu/đọc tham số cấu hình động cho ma trận duyệt, matching tolerance |
| **CHUẨN HÓA** | Bổ sung mục §1.6 thống nhất enum toàn hệ thống | Tránh lệch giữa các tài liệu |
| **CHUẨN HÓA** | Bổ sung Phụ lục §11.1 mapping UC ↔ API | Hỗ trợ truy vết và testing |

---

**KẾT THÚC TÀI LIỆU ĐẶC TẢ API V3.0**

*Tài liệu này được tạo ra ngày 26/05/2026 dựa trên rà soát chéo giữa 9 tài liệu kỹ thuật của dự án Hệ thống Quản lý Mua hàng. Mọi thay đổi/bổ sung so với v2.0 đã được liệt kê chi tiết tại Phụ lục §11.3.*
