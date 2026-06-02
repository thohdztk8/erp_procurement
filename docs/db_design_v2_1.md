# Thiết Kế Cơ Sở Dữ Liệu — Hệ Thống Quản Lý Mua Hàng Doanh Nghiệp Sản Xuất

**Phiên bản:** 2.1 (Bổ sung 4 bảng nghiệp vụ còn thiếu so với v2.0)  
**Ngày cập nhật:** 26/05/2026  
**Tham chiếu:** UseCase Document v2.0, API Document v3.0, Khảo sát nghiệp vụ thực tế, Meeting note  
**Hệ quản trị DB:** Microsoft SQL Server (MSSQL)  
**Giải pháp Backend:** Python + Django REST Framework  

---

## Lịch sử thay đổi v2.1 so với v2.0

| Loại | Đối tượng | Lý do |
| :--- | :--- | :--- |
| **BỔ SUNG** | Bảng `QuotationVersions` (Module 5) | Lưu lịch sử các phiên bản báo giá NCC. Đáp ứng UC-11 và Meeting note ("Xử lý khi supplier báo nhiều lần"). |
| **BỔ SUNG** | Bảng `CreditNotes` (Module 8) | Quản lý chứng từ giảm trừ công nợ NCC khi trả hàng sau thanh toán. Đáp ứng UC-16C, UC-20, Khảo sát 6.5. |
| **BỔ SUNG** | Bảng `DebitNotes` (Module 8) | Quản lý chứng từ NCC điều chỉnh giảm giá sau khi đã hóa đơn. Đáp ứng UC-20 (luồng thay thế 6b). |
| **BỔ SUNG** | Bảng `SupplierEvaluations` (Module 10 mới) | Lưu vết đánh giá NCC định kỳ. Đáp ứng UC-24, Khảo sát 2.3. |
| **BỔ SUNG** | Bảng `SupplierEvaluationCriteria` (Module 10 mới) | Lưu chi tiết điểm từng tiêu chí trong 1 lần đánh giá. |
| **BỔ SUNG** | Bảng `EmailTemplates` (Module 9) | Lưu template email dùng chung (mời báo giá, alert PR khẩn, thông báo duyệt...). Đáp ứng UC-10 và các luồng notification. |
| **BỔ SUNG** | Index hỗ trợ các bảng mới | Tối ưu truy vấn lịch sử báo giá, công nợ NCC, đánh giá NCC theo kỳ. |

---

## 1. Kiến Trúc Tổng Quan & Luồng Dữ Liệu v2.0

Hệ thống được thiết kế theo mô hình dữ liệu quan hệ chặt chẽ nhằm tự động hóa chuỗi cung ứng nội bộ từ khâu đề xuất nhu cầu đến khâu đối soát kế toán. Phiên bản 2.0 tập trung giải quyết các bài toán về:
1. **Phê duyệt đa cấp động (Approval Matrix):** Tách biệt cấu hình hạn mức ra khỏi mã nguồn Backend.
2. **Bảo mật cổng thông tin NCC (Vendor Portal Security):** Mã hóa Token một chiều chống rò rỉ dữ liệu thầu.
3. **Toàn vẹn dữ liệu vật tư tự do ("Other" Items):** Chặn lỗi khuyết thông tin định danh bằng kiểm tra loại trừ chéo.
4. **Kiểm soát khối lượng lũy tiến:** Chặn cứng hành vi gom mua hoặc nhận kho vượt định mức.
5. **Số hóa kiểm định kho (IQC & Photo Evidence):** Phân loại chi tiết hàng đạt/lỗi kèm cơ chế lưu trữ JSON chuỗi ảnh minh chứng.

---

## 2. Từ Điển Dữ Liệu Chi Tiết (Data Dictionary)

### 2.1 Module 1: AUTHENTICATION & PHÂN QUYỀN (RBAC)
Hệ thống kiểm soát truy cập dựa trên vai trò, phân tách người dùng theo cấu trúc Chi nhánh -> Phòng ban -> Vai trò chức năng.

#### Bảng: `Branches` (Chi nhánh / Nhà máy)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `branch_id` | `INT` | PK, Identity | Mã định danh tự tăng của chi nhánh |
| `branch_code` | `NVARCHAR(20)` | Unique, Not Null | Mã chi nhánh (Ví dụ: CN-HN, CN-NB) |
| `branch_name` | `NVARCHAR(200)` | Not Null | Tên chi nhánh / nhà máy |
| `address` | `NVARCHAR(500)` | Null | Địa chỉ vật lý |
| `is_active` | `BIT` | Not Null, Default 1 | Trạng thái hoạt động (1: Hoạt động, 0: Khóa) |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời gian khởi tạo bản ghi |
| `updated_at` | `DATETIME2` | Null | Thời gian cập nhật gần nhất |

#### Bảng: `Departments` (Phòng ban / Bộ phận)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `dept_id` | `INT` | PK, Identity | Mã định danh tự tăng của phòng ban |
| `dept_code` | `NVARCHAR(20)` | Unique, Not Null | Mã phòng ban (Ví dụ: PUR, PROD, ACC) |
| `dept_name` | `NVARCHAR(200)` | Not Null | Tên phòng ban / bộ phận |
| `branch_id` | `INT` | FK | Liên kết bảng `Branches(branch_id)` |
| `parent_dept_id` | `INT` | Null | Khóa ngoại đệ quy tạo cấu trúc cây phòng ban |
| `is_active` | `BIT` | Not Null, Default 1 | Trạng thái hoạt động |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời gian tạo |

#### Bảng: `Roles` (Vai trò người dùng)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `role_id` | `INT` | PK, Identity | Mã vai trò |
| `role_code` | `NVARCHAR(50)` | Unique, Not Null | Mã vai trò (Ví dụ: BUYER, DEPT_HEAD, GD) |
| `role_name` | `NVARCHAR(100)` | Not Null | Tên hiển thị của vai trò |
| `description` | `NVARCHAR(300)` | Null | Mô tả chức năng vai trò |
| `is_active` | `BIT` | Not Null, Default 1 | Trạng thái |

#### Bảng: `Users` (Tài khoản nhân viên)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `user_id` | `INT` | PK, Identity | Định danh tài khoản |
| `username` | `NVARCHAR(50)` | Unique, Not Null | Tên đăng nhập hệ thống |
| `password_hash` | `NVARCHAR(255)` | Not Null | Chuỗi mật khẩu băm bảo mật (BCrypt) |
| `full_name` | `NVARCHAR(150)` | Not Null | Họ và tên nhân viên |
| `email` | `NVARCHAR(100)` | Unique, Not Null | Email công vụ nhận thông báo phê duyệt |
| `phone` | `NVARCHAR(20)` | Null | Số điện thoại |
| `branch_id` | `INT` | FK | Liên kết bảng `Branches` |
| `dept_id` | `INT` | FK | Liên kết bảng `Departments` |
| `role_id` | `INT` | FK | Liên kết bảng `Roles` |
| `is_active` | `BIT` | Not Null, Default 1 | Trạng thái hoạt động |
| `login_fail_count` | `INT` | Not Null, Default 0 | Số lần đăng nhập sai liên tiếp |
| `locked_until` | `DATETIME2` | Null | Thời hạn khóa tài khoản nếu sai quá số lần |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày tạo tài khoản |

#### Bảng: `Permissions` (Danh mục quyền hạn hệ thống)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `permission_id` | `INT` | PK, Identity | Định danh quyền |
| `permission_code`| `NVARCHAR(100)` | Unique, Not Null | Mã quyền chức năng (Ví dụ: `PR_APPROVE`, `IPO_CREATE`) |
| `permission_name`| `NVARCHAR(150)` | Not Null | Tên hiển thị quyền |
| `module_group` | `NVARCHAR(50)` | Not Null | Nhóm phân hệ (Ví dụ: AUTH, PR, KHO) |

#### Bảng: `RolePermissions` (Bảng trung gian phân quyền)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `role_id` | `INT` | PK, FK | Liên kết bảng `Roles(role_id)` |
| `permission_id` | `INT` | PK, FK | Liên kết bảng `Permissions(permission_id)` |
| `assigned_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời gian cấp quyền |

---

### 2.2 Module 2: MASTER DATA (DANH MỤC GỐC DÙNG CHUNG)

#### Bảng: `MaterialCategories` (Phân loại vật tư)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `category_id` | `INT` | PK, Identity | Mã danh mục vật tư |
| `category_code` | `NVARCHAR(20)` | Unique, Not Null | Mã nhóm hàng (Ví dụ: NVL, CCDC, THIETBI) |
| `category_name` | `NVARCHAR(150)` | Not Null | Tên nhóm hàng |
| `is_active` | `BIT` | Not Null, Default 1 | Trạng thái |

#### Bảng: `Materials` (Danh mục vật tư chuẩn)
*Lưu ý kiến trúc:* Cột `material_name` và `description` được đăng ký cấu hình **Full-Text Index (Vietnamese - Code 1066)** để phục vụ truy vấn tìm kiếm nâng cao từ khóa tự do ở tầng Backend.
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `material_id` | `INT` | PK, Identity | Mã định danh vật tư |
| `material_code` | `NVARCHAR(50)` | Unique, Not Null | Mã code vật tư quản lý (SKU) |
| `material_name` | `NVARCHAR(300)` | Not Null | Tên chi tiết vật tư |
| `category_id` | `INT` | FK | Liên kết bảng `MaterialCategories` |
| `uom` | `NVARCHAR(30)` | Not Null | Đơn vị tính (kg, chiếc, mét, khối,...) |
| `min_stock_level`| `DECIMAL(18,4)` | Not Null, Default 0 | Ngưỡng tồn kho tối thiểu an toàn |
| `description` | `NVARCHAR(500)` | Null | Mô tả thông số kỹ thuật hàng hóa |
| `is_other` | `BIT` | Not Null, Default 0 | Cờ phân biệt (1: Hàng ngoài danh mục free text, 0: Hàng chuẩn) |
| `is_active` | `BIT` | Not Null, Default 1 | Trạng thái |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày tạo |

#### Bảng: `Suppliers` (Danh mục Nhà cung cấp)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `supplier_id` | `INT` | PK, Identity | Mã định danh nhà cung cấp |
| `supplier_code` | `NVARCHAR(30)` | Unique, Not Null | Mã code quản lý nhà cung cấp |
| `supplier_name` | `NVARCHAR(250)` | Not Null | Tên đầy đủ của doanh nghiệp NCC |
| `tax_code` | `NVARCHAR(20)` | Null | Mã số thuế |
| `contact_name` | `NVARCHAR(100)` | Null | Đại diện liên hệ |
| `contact_email` | `NVARCHAR(100)` | Not Null | Email chính thức tiếp nhận link báo giá |
| `contact_phone` | `NVARCHAR(20)` | Null | Số điện thoại liên hệ |
| `address` | `NVARCHAR(500)` | Null | Địa chỉ trụ sở |
| `rating_score` | `DECIMAL(5,2)` | Not Null, Default 5.00 | Điểm xếp hạng NCC tự động tính toán (1.00 -> 5.00) |
| `is_active` | `BIT` | Not Null, Default 1 | Trạng thái hoạt động |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày tạo |

#### Bảng: `SupplierContractPrices` (Bá giá thỏa thuận khung / Giá hợp đồng)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `contract_price_id`| `INT` | PK, Identity | Định danh đơn giá thỏa thuận |
| `supplier_id` | `INT` | FK | Liên kết bảng `Suppliers` |
| `material_id` | `INT` | FK | Liên kết bảng `Materials` |
| `contract_unit_price`| `DECIMAL(18,2)`| Not Null | Đơn giá ký kết cố định làm căn cứ đối soát |
| `valid_from` | `DATETIME2` | Not Null | Ngày bắt đầu hiệu lực giá |
| `valid_to` | `DATETIME2` | Not Null | Ngày hết hiệu lực giá |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày lưu |
| *Ràng buộc Check* | `CK_ContractPrices_Dates` | `valid_to >= valid_from` | Ngày kết thúc không được nhỏ hơn ngày bắt đầu |

---

### 2.3 CẤU HÌNH MA TRẬN PHÊ DUYỆT ĐỘNG (APPROVAL MATRIX)

#### Bảng: `ApprovalWorkflows` (Luồng quy trình phê duyệt)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `workflow_id` | `INT` | PK, Identity | Định danh luồng quy trình |
| `workflow_name` | `NVARCHAR(100)` | Not Null | Tên quy trình phê duyệt hiển thị |
| `object_type` | `NVARCHAR(50)` | Not Null | Loại chứng từ áp dụng: 'PR_NORMAL', 'PR_URGENT', 'IPO' |
| `min_amount` | `DECIMAL(18,2)`| Not Null, Default 0 | Giá trị tổng tiền tối thiểu áp dụng luồng này |
| `max_amount` | `DECIMAL(18,2)`| Null | Giá trị tổng tiền tối đa áp dụng (Null = Vô cực) |
| `dept_id` | `INT` | FK, Null | Áp dụng riêng cho 1 bộ phận (Null = Áp dụng toàn công ty) |
| `is_active` | `BIT` | Not Null, Default 1 | Trạng thái hoạt động |
| *Ràng buộc Check* | `CK_ApprovalWorkflows_Amount` | `max_amount IS NULL OR max_amount >= min_amount` |

#### Bảng: `ApprovalWorkflowSteps` (Cấu hình chi tiết các cấp duyệt)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `step_id` | `INT` | PK, Identity | Định danh bước duyệt |
| `workflow_id` | `INT` | FK | Liên kết bảng `ApprovalWorkflows(workflow_id)` |
| `step_sequence` | `INT` | Not Null | Thứ tự tuyến tính thực thi duyệt (Bước 1, Bước 2, Bước 3...) |
| `role_id` | `INT` | FK | Vai trò có thẩm quyền phê duyệt ở bước này |

---

### 2.4 Module 3: PURCHASE REQUISITION (YÊU CẦU MUA HÀNG PR THƯỜNG & KHẨN)

#### Bảng: `PurchaseRequisitions` (Đơn yêu cầu mua hàng PR)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `pr_id` | `INT` | PK, Identity | Định danh đơn PR |
| `pr_code` | `NVARCHAR(30)` | Unique, Not Null | Mã số đơn PR tự sinh theo định dạng quy chuẩn |
| `requester_user_id`| `INT` | FK | Người lập đề xuất. Liên kết bảng `Users` |
| `branch_id` | `INT` | FK | Chi nhánh yêu cầu. Liên kết bảng `Branches` |
| `dept_id` | `INT` | FK | Phòng ban yêu cầu. Liên kết bảng `Departments` |
| `priority_level` | `NVARCHAR(20)` | Not Null, Default 'NORMAL' | Mức độ ưu tiên xử lý đơn: 'NORMAL', 'URGENT' |
| `urgent_reason` | `NVARCHAR(500)` | Null | Lý do đề xuất khẩn (Bắt buộc nếu priority là URGENT) |
| `urgency_impact` | `NVARCHAR(500)` | Null | Tác động vận hành nếu hàng chậm (Bắt buộc nếu URGENT) |
| `pr_status` | `NVARCHAR(30)` | Not Null, Default 'DRAFT' | Trạng thái: DRAFT, PENDING, APPROVED, REJECTED, CANCELLED |
| `total_estimated_amount`| `DECIMAL(18,2)`| Not Null, Default 0| Tổng ngân sách ước tính ban đầu của đơn PR |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày tạo đơn |
| `updated_at` | `DATETIME2` | Null | Ngày chỉnh sửa |
| *Ràng buộc Check* | `CK_PR_Priority` | Khóa giá trị trong tập hợp `('NORMAL', 'URGENT')` |
| *Ràng buộc Check* | `CK_PR_UrgentFields` | Đảm bảo nếu `priority_level = 'URGENT'` thì không được phép để khuyết `urgent_reason` và `urgency_impact`. |

#### Bảng: `PRItems` (Chi tiết các mặt hàng trong đơn PR)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `pr_item_id` | `INT` | PK, Identity | Định danh dòng mặt hàng PR |
| `pr_id` | `INT` | FK | Liên kết bảng `PurchaseRequisitions` |
| `material_id` | `INT` | FK, Null | Mã hàng trong Master Data (Để NULL nếu mua hàng tự do) |
| `material_name_other`| `NVARCHAR(300)`| Null | Tên chi tiết hàng tự do ngoài danh mục nhập tay |
| `qty_requested` | `DECIMAL(18,4)`| Not Null | Số lượng hoặc khối lượng phòng ban đề xuất mua |
| `qty_ordered` | `DECIMAL(18,4)`| Not Null, Default 0 | Cột theo dõi lũy tiến số lượng đã được gom lên đơn Đặt hàng |
| `qty_received` | `DECIMAL(18,4)`| Not Null, Default 0 | Cột theo dõi lũy tiến số lượng thực tế Kho đã nhập kho thành công |
| `estimated_unit_price`| `DECIMAL(18,2)`| Not Null, Default 0| Giá dự kiến một đơn vị phục vụ duyệt hạn mức ban đầu |
| `required_deadline`| `DATETIME2` | Not Null | Hạn cuối yêu cầu hàng về tới nhà máy phục vụ sản xuất |
| `item_status` | `NVARCHAR(30)` | Not Null, Default 'PENDING'| Trạng thái dòng hàng xử lý |
| *Ràng buộc Check* | `CK_PRItems_QtyPositive` | `qty_requested > 0` | Số lượng yêu cầu phải lớn hơn 0 |
| *Ràng buộc Check* | `CK_PRItems_MaterialCheck` | Kiểm tra loại trừ chéo: Khắc phục Gap 3 của tài liệu AIP. Bản ghi bắt buộc phải điền `material_id` (hàng chuẩn) HOẶC nhập tay văn bản tự do vào trường `material_name_other` (hàng ngoài danh mục), không được phép trống cả 2 và không được điền đồng thời cả 2. |
| *Ràng buộc Check* | `CK_PRItems_QtyOrderedSanity`| `qty_ordered <= qty_requested` | Khắc phục Gap 4 của tài liệu AIP: Chặn cứng không cho phép tổng số lượng gom mua đặt hàng lũy tiến vượt mức yêu cầu ban đầu. |
| *Ràng buộc Check* | `CK_PRItems_QtyReceivedSanity`| `qty_received <= qty_ordered` | Khắc phục Gap 4 của tài liệu AIP: Số lượng kho thực nhận lũy tiến không được vượt qua tổng khối lượng đặt mua chính thức. |

#### Bảng: `DocumentApprovalProgress` (Theo dõi tiến độ duyệt thực tế)
Lưu dấu vết lịch sử toàn bộ các bước nhấn phê duyệt thực tế của một chứng từ theo cấu hình ma trận phê duyệt động.
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `progress_id` | `INT` | PK, Identity | Định danh bản ghi tiến độ |
| `document_type` | `NVARCHAR(50)` | Not Null | Loại chứng từ đang thực thi xử lý duyệt: 'PR' hoặc 'IPO' |
| `document_id` | `INT` | Not Null | ID trỏ đến bảng chứng từ thực tế tương ứng (`pr_id` hoặc `ipo_id`) |
| `step_sequence` | `INT` | Not Null | Cấp bậc bước duyệt tương ứng với cấu hình hệ thống |
| `approver_user_id` | `INT` | FK, Null | Tài khoản nhân sự đã nhấn nút xử lý phê duyệt. Liên kết `Users` |
| `approval_status` | `NVARCHAR(20)` | Not Null | Trạng thái thao tác bước: 'PENDING', 'APPROVED', 'REJECTED' |
| `comment` | `NVARCHAR(500)` | Null | Ý kiến nhận xét, phản hồi hoặc lý do từ chối đơn chứng từ |
| `action_date` | `DATETIME2` | Null | Ngày giờ thực hiện bấm nút tác vụ duyệt |

#### Bảng: `PRStatusHistory` (Lịch sử chuyển đổi trạng thái tổng đơn PR)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `history_id` | `INT` | PK, Identity | Mã định danh bản ghi lịch sử trạng thái |
| `pr_id` | `INT` | FK | Liên kết bảng `PurchaseRequisitions` |
| `from_status` | `NVARCHAR(30)` | Not Null | Trạng thái cũ trước khi chuyển |
| `to_status` | `NVARCHAR(30)` | Not Null | Trạng thái mới sau khi chuyển đổi |
| `changed_by_user_id`| `INT` | FK | Tài khoản người dùng thực hiện. Liên kết bảng `Users` |
| `note` | `NVARCHAR(500)` | Null | Ghi chú lý do thay đổi trạng thái tổng đơn |
| `changed_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời điểm ghi nhận thao tác hệ thống |

---

### 2.5 Module 4: CART & ORDER (GOM HÀNG VÀ ĐIỀU PHỐI ĐẶT HÀNG TỔNG QUÁT)

#### Bảng: `Carts` (Giỏ gom hàng của Phòng mua hàng)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `cart_id` | `INT` | PK, Identity | Mã giỏ gom hàng |
| `cart_title` | `NVARCHAR(150)` | Not Null | Tên giỏ gom phân loại công việc (Ví dụ: Gom mua Thép xây dựng tháng 5) |
| `buyer_user_id` | `INT` | FK | Nhân viên điều phối phòng mua hàng làm chủ giỏ. Liên kết `Users` |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời điểm gom giỏ |

#### Bảng: `CartPRItems` (Bảng trung gian liên kết dòng PR vào Giỏ hàng)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `cart_id` | `INT` | PK, FK | Liên kết bảng `Carts` |
| `pr_item_id` | `INT` | PK, FK | Liên kết bảng `PRItems` |
| `qty_in_cart` | `DECIMAL(18,4)`| Not Null | Số lượng dòng hàng bóc tách đưa vào giỏ hàng này |
| `added_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời gian thêm hàng |
| *Ràng buộc Check* | `CK_CartPRItems_Qty` | `qty_in_cart > 0` | Số lượng đưa vào giỏ hàng xử lý bắt buộc lớn hơn 0 |

#### Bảng: `Orders` (Phiên làm việc điều phối thu thập báo giá tổng quát)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `order_id` | `INT` | PK, Identity | Định danh phiên đơn hàng đặt mua tổng quát |
| `order_code` | `NVARCHAR(30)` | Unique, Not Null | Mã phiên đơn hàng hệ thống |
| `buyer_user_id` | `INT` | FK | Nhân viên điều phối mua hàng chịu trách nhiệm. Liên kết `Users` |
| `order_status` | `NVARCHAR(30)` | Not Null, Default 'DRAFT'| Trạng thái: DRAFT, QUOTING, COMPLETED |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày lập phiên |

#### Bảng: `OrderItems` (Chi tiết tổng khối lượng các mặt hàng gom mua cần báo giá)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `order_item_id` | `INT` | PK, Identity | Định danh dòng mặt hàng đặt mua tổng quát |
| `order_id` | `INT` | FK | Liên kết bảng `Orders` |
| `material_id` | `INT` | FK, Null | Mã hàng chuẩn từ danh mục (NULL nếu là hàng tự do nhập tay) |
| `material_name_other`| `NVARCHAR(300)`| Null | Tên chi tiết hàng tự do ngoài danh mục kế thừa từ PR gốc |
| `qty_total_ordered`| `DECIMAL(18,4)`| Not Null | Tổng khối lượng gộp lại từ nhiều đơn PR để đi ép giá NCC |
| *Ràng buộc Check* | `CK_OrderItems_Qty` | `qty_total_ordered > 0` |
| *Ràng buộc Check* | `CK_OrderItems_MaterialCheck`| Đảm bảo tính toàn vẹn thông tin mặt hàng, không trống cả 2 và không điền cả 2 |

#### Bảng: `OrderItemPRLinks` (Bảng phân rã chi tiết nguồn gốc dòng OrderItem xuất phát từ các PR nào)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `order_item_id` | `INT` | PK, FK | Liên kết bảng `OrderItems` |
| `pr_item_id` | `INT` | PK, FK | Liên kết bảng `PRItems` |
| `qty_linked` | `DECIMAL(18,4)`| Not Null | Số lượng bóc tách từ dòng PR chuyển dịch sang dòng OrderItem |

#### Bảng: `OrderSuppliers` (Danh sách các NCC cạnh tranh được mời tham gia chào giá cho phiên đơn hàng)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `order_id` | `INT` | PK, FK | Liên kết bảng `Orders` |
| `supplier_id` | `INT` | PK, FK | Liên kết bảng `Suppliers` |
| `assigned_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời điểm mời tham gia chào thầu |

---

### 2.6 Module 5: QUOTATION PORTAL (CỔNG THU THẬP BÁO GIÁ NCC BẢO MẬT)

#### Bảng: `QuotationRequests` (Yêu cầu gửi báo giá tới từng NCC)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `q_request_id` | `INT` | PK, Identity | Định danh yêu cầu báo giá |
| `order_id` | `INT` | FK | Liên kết đơn hàng tổng quát `Orders` |
| `supplier_id` | `INT` | FK | Liên kết danh mục nhà cung cấp nhận thư `Suppliers` |
| `deadline_submission`| `DATETIME2` | Not Null | Hạn cuối cùng hệ thống mở cổng nhận phản hồi báo giá tự động |
| `sent_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời điểm hệ thống gửi mail tự động kèm link Token |

#### Bảng: `QuotationTokens` (Quản lý chuỗi khóa mã bảo mật truy cập cổng thông tin NCC)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `token_id` | `INT` | PK, Identity | Định danh khóa Token |
| `q_request_id` | `INT` | FK | Liên kết bảng `QuotationRequests` |
| `token` | `NVARCHAR(128)` | Unique, Not Null | Chuỗi Hash bảo mật (SHA-256 mã hóa một chiều ở Backend sinh ra), khắc phục Gap 2 tài liệu AIP. |
| `expires_at` | `DATETIME2` | Not Null | Thời điểm hết hạn hiệu lực của link mã khóa |
| `is_used` | `BIT` | Not Null, Default 0 | Cờ chặn tái sử dụng: Tự động chuyển đổi thành 1 ngay sau khi NCC bấm nút Submit đơn giá để bảo vệ dữ liệu tuyệt đối. |
| `used_at` | `DATETIME2` | Null | Thời điểm NCC nhấn nút nộp đơn chốt thầu báo giá |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời điểm sinh chuỗi Token |

#### Bảng: `Quotations` (Tổng đơn nộp báo giá phản hồi từ Nhà cung cấp)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `quotation_id` | `INT` | PK, Identity | Định danh đơn báo giá |
| `q_request_id` | `INT` | FK | Liên kết bảng `QuotationRequests` |
| `supplier_id` | `INT` | FK | Nhà cung cấp nộp giá. Liên kết bảng `Suppliers` |
| `submitted_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời điểm nộp đơn thực tế từ giao diện web portal |
| `delivery_lead_time_days`|`INT` | Not Null | Thời gian giao hàng cam kết của NCC (Tính theo số ngày) |
| `payment_terms_note`| `NVARCHAR(200)`| Null | Ghi chú điều khoản công nợ thanh toán đề xuất của NCC |
| `total_quote_amount`| `DECIMAL(18,2)`| Not Null, Default 0| Tổng giá trị gói thầu báo giá của NCC |
| `is_selected` | `BIT` | Not Null, Default 0 | Cờ đánh dấu phương án mua hàng tối ưu được phòng mua hàng lựa chọn |

#### Bảng: `QuotationItems` (Chi tiết đơn giá chào thầu từng mặt hàng của NCC)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `q_item_id` | `INT` | PK, Identity | Định danh dòng báo giá |
| `quotation_id` | `INT` | FK | Liên kết bảng `Quotations` |
| `order_item_id` | `INT` | FK | Liên kết bảng `OrderItems` |
| `quoted_unit_price`| `DECIMAL(18,2)`| Not Null | Đơn giá chào thầu NCC cam kết cung cấp |
| `supplier_note` | `NVARCHAR(300)`| Null | Ghi chú quy cách kỹ thuật riêng của NCC cho mặt hàng |
| *Ràng buộc Check* | `CK_QuotationItems_Price`| `quoted_unit_price >= 0` | Đơn giá chào thầu không được âm |

#### Bảng: `QuotationVersions` (Lịch sử các phiên bản báo giá NCC) [BỔ SUNG v2.1]
*Mục đích nghiệp vụ:* Đáp ứng UC-11 và Meeting note — "Sau khi submit, nếu còn trong deadline báo giá và đơn hàng chưa bị chốt thì cho phép edit". NCC có thể submit lại báo giá nhiều lần; hệ thống không ghi đè bản ghi cũ mà lưu vết tất cả các phiên bản phục vụ kiểm toán và đối chiếu khi NCC cố tình "đánh úp" giá vào phút chót.

| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `version_id` | `INT` | PK, Identity | Định danh phiên bản báo giá lưu vết |
| `quotation_id` | `INT` | FK, Not Null | Liên kết tới bản ghi gốc trong bảng `Quotations` (bản hiện hành) |
| `version_number` | `INT` | Not Null | Số thứ tự phiên bản (Bắt đầu từ 1, tăng dần mỗi lần NCC submit lại) |
| `is_current` | `BIT` | Not Null, Default 0 | Cờ đánh dấu phiên bản hiện hành (1: Đang dùng cho so sánh, 0: Lưu lịch sử) |
| `snapshot_total_amount` | `DECIMAL(18,2)` | Not Null | Tổng giá trị báo giá tại thời điểm phiên bản này |
| `snapshot_lead_time_days` | `INT` | Not Null | Lead-time tại phiên bản này |
| `snapshot_payment_terms`| `NVARCHAR(200)`| Null | Điều khoản thanh toán đề xuất tại phiên bản này |
| `snapshot_items_json` | `NVARCHAR(MAX)` | Not Null | Chụp ảnh toàn bộ chi tiết dòng hàng `QuotationItems` (đơn giá, ghi chú) tại thời điểm submit dưới dạng chuỗi JSON. Phục vụ truy vết khi NCC chối bỏ giá đã chào. |
| `submitted_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời điểm NCC nhấn submit phiên bản này |
| `submitted_ip` | `NVARCHAR(45)` | Null | Địa chỉ IP của NCC khi submit (phục vụ điều tra gian lận) |
| `change_summary` | `NVARCHAR(500)` | Null | Tóm tắt thay đổi so với phiên bản trước (Backend tự sinh khi diff: "Giảm giá item A từ 250k → 242k") |
| *Ràng buộc Unique* | `UQ_QuotationVersions_Number` | `UNIQUE (quotation_id, version_number)` | Đảm bảo không trùng số phiên bản trong cùng 1 báo giá |
| *Ràng buộc Check* | `CK_QuotationVersions_VersionPositive` | `version_number > 0` | Số phiên bản phải dương |
| *Ràng buộc Check* | `CK_QuotationVersions_AmountNonNegative` | `snapshot_total_amount >= 0` | Tổng tiền không được âm |

**Quy tắc vận hành (Backend bảo đảm):**
- Mỗi lần NCC submit lại báo giá trong portal, Backend phải: (1) Tạo bản ghi mới trong `QuotationVersions` với `version_number = max(version_number) + 1`, `is_current = 1`; (2) Hạ cờ `is_current = 0` của tất cả phiên bản cũ; (3) Cập nhật bản ghi trong `Quotations` với dữ liệu mới nhất.
- Khi bảng so sánh giá ở UC-12 truy vấn, chỉ lấy phiên bản `is_current = 1`. Khi cần audit, truy vấn toàn bộ phiên bản theo `quotation_id`.
- Khi NCC quá hạn deadline hoặc Order đã chốt IPO, không cho phép tạo phiên bản mới (chặn ở tầng Backend + kiểm tra `QuotationTokens.is_used`).

---

### 2.7 Module 6: INTERNAL PO (IPO PHÊ DUYỆT ĐA PHIÊN BẢN VÀ QUẢN LÝ BIẾN ĐỘNG)

#### Bảng: `IPOs` (Đơn đặt hàng mua nội bộ chính thức)
Bảng dữ liệu được thiết kế quản lý lịch sử biến động đa phiên bản nâng cao theo quy chuẩn nghiệp vụ v2.0.
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `ipo_id` | `INT` | PK, Identity | Mã ID duy nhất định danh một thực thể phiên bản cụ thể |
| `ipo_code` | `NVARCHAR(30)` | Not Null | Mã số đơn PO quản lý chung của luồng giao dịch |
| `version` | `INT` | Not Null, Default 1 | Đếm số thứ tự phiên bản tài liệu (Mặc định bắt đầu từ V1, tăng tịnh tiến nếu chỉnh sửa đơn) |
| `is_latest` | `BIT` | Not Null, Default 1 | Chỉ số trạng thái hiệu lực (1: Phiên bản mới nhất có giá trị thực thi pháp lý, 0: Phiên bản cũ lưu lịch sử) |
| `order_id` | `INT` | FK | Liên kết phiên làm việc nguồn `Orders` |
| `supplier_id` | `INT` | FK | Đối tác NCC được chốt mua hàng. Liên kết bảng `Suppliers` |
| `buyer_user_id` | `INT` | FK | Nhân viên điều phối chịu trách nhiệm theo dõi đơn. Liên kết `Users` |
| `total_amount` | `DECIMAL(18,2)`| Not Null | Tổng giá trị tài chính chốt đặt mua của đơn hàng |
| `ipo_status` | `NVARCHAR(30)` | Not Null, Default 'DRAFT'| Trạng thái đơn: DRAFT, PENDING, APPROVED, REJECTED |
| `signed_pdf_path` | `NVARCHAR(500)`| Null | Đường dẫn máy chủ lưu tệp PDF đơn hàng có dấu mộc scan |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày khởi tạo phiên bản |
| `updated_at` | `DATETIME2` | Null | Ngày sửa đổi |
| *Ràng buộc Check* | `CK_IPOs_Status` | Tập giá trị giới hạn trong `('DRAFT', 'PENDING', 'APPROVED', 'REJECTED')` |

#### Bảng: `IPOItems` (Chi tiết số lượng và đơn giá chốt mua hàng của phiên bản IPO)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `ipo_item_id` | `INT` | PK, Identity | Định danh dòng hàng IPO |
| `ipo_id` | `INT` | FK | Liên kết trực tiếp theo thực thể mã ID phiên bản cụ thể của bảng `IPOs` |
| `order_item_id` | `INT` | FK | Liên kết dòng hàng đặt mua tổng quát `OrderItems` |
| `qty_final` | `DECIMAL(18,4)`| Not Null | Khối lượng chốt đặt mua chính thức sau đàm phán |
| `unit_price_final` | `DECIMAL(18,2)`| Not Null | Đơn giá chốt đặt mua chính thức sau đàm phán |
| `item_total_amount`| `DECIMAL(18,2)`| Not Null | Tổng giá trị thành tiền dòng hàng (`qty_final * unit_price_final`) |
| *Ràng buộc Check* | `CK_IPOItems_Values` | `qty_final > 0 AND unit_price_final >= 0` | Chặn dữ liệu số lượng âm hoặc đơn giá lỗi |

---

### 2.8 Module 7: WAREHOUSE MANAGEMENT (KHO VẬN: QC PHÂN LOẠI, HOÀN TRẢ & TỒN KHO)

#### Bảng: `StockReceipts` (Đơn nhập kho hàng hóa thực tế giao tới bãi)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `receipt_id` | `INT` | PK, Identity | Định danh đơn nhận kho |
| `receipt_code` | `NVARCHAR(30)` | Unique, Not Null | Mã số phiếu nhập kho tự động sinh của hệ thống |
| `ipo_id` | `INT` | FK | Đối chiếu chéo đơn đặt mua IPO gốc đã được `APPROVED` |
| `warehouse_keeper_id`|`INT` | FK | Thủ kho chịu trách nhiệm cân đo kiểm đếm. Liên kết `Users` |
| `received_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời gian thực hiện mở phiếu hạ hàng kiểm hàng |
| `delivery_note_ref`| `NVARCHAR(100)`| Null | Mã số hóa đơn chứng từ phiếu giao hàng của đơn vị vận tải / NCC |
| `note` | `NVARCHAR(500)` | Null | Ghi chú tình trạng xe giao hàng |

#### Bảng: `StockReceiptItems` (Đặc tả chi tiết kiểm định phân loại hàng đạt/hỏng của QC đầu vào v2.0)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `receipt_item_id` | `INT` | PK, Identity | Định danh dòng kiểm định hàng nhập kho |
| `receipt_id` | `INT` | FK | Liên kết bảng `StockReceipts` |
| `material_id` | `INT` | FK, Null | Mã danh mục hàng chuẩn (NULL nếu kiểm hàng tự do nhập tay) |
| `material_name_other`| `NVARCHAR(300)`| Null | Tên hàng tự do kế thừa phục vụ đối soát |
| `qty_ordered` | `DECIMAL(18,4)`| Not Null | Số lượng chốt mua ký kết trên đơn hàng IPO phục vụ hiển thị đối chiếu |
| `qty_received` | `DECIMAL(18,4)`| Not Null | Tổng số lượng thực tế nhà xe giao đến bến bãi |
| `qty_passed` | `DECIMAL(18,4)`| Not Null | Số lượng kiểm định đạt chuẩn chất lượng kỹ thuật, nhập kho khả dụng |
| `qty_failed` | `DECIMAL(18,4)`| Not Null | Số lượng hàng hỏng, móp méo, sai quy cách bị loại bỏ |
| `photo_paths` | `NVARCHAR(MAX)`| Null | Chuỗi định dạng văn bản JSON lưu danh sách các đường dẫn ảnh chụp vật lý minh chứng lỗi sản phẩm. |
| *Ràng buộc Check* | `CK_StockReceiptItems_QtyLogic` | Kiểm tra tính toán số lượng hợp lệ mức database: Các trường số lượng không được âm và bắt buộc tuân thủ phương trình cân bằng: `qty_received = qty_passed + qty_failed` |
| *Ràng buộc Check* | `CK_StockReceiptItems_MaterialCheck`| Chặn khuyết thông tin mặt hàng chuẩn hoặc tự do tương tự PRItems |
| *Ràng buộc Check* | `CK_StockReceiptItems_PhotoMandatory`| Quy tắc nghiệp vụ v2.0: Đảm bảo nếu xuất hiện hàng lỗi phát sinh (`qty_failed > 0`), hệ thống chặn bắt buộc trường `photo_paths` không được để NULL (Phải upload ảnh bằng chứng). |

#### Bảng: `Inventory` (Quản lý số dư tồn kho tổng hợp theo chi nhánh)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `inventory_id` | `INT` | PK, Identity | Định danh dòng thẻ kho |
| `branch_id` | `INT` | PK, FK | Khóa chính phức liên kết chi nhánh nhà máy quản lý kho |
| `material_id` | `INT` | PK, FK | Khóa chính phức liên kết vật tư chuẩn danh mục |
| `qty_on_hand` | `DECIMAL(18,4)`| Not Null, Default 0 | Số lượng tồn kho vật lý thực tế tại bãi (Tăng tịnh tiến theo trường `qty_received` khi nhập kho) |
| `qty_available` | `DECIMAL(18,4)`| Not Null, Default 0 | Số lượng tồn kho khả dụng cấp phát cho xưởng sản xuất (Tăng theo `qty_passed`) |
| `qty_quarantine` | `DECIMAL(18,4)`| Not Null, Default 0 | Khối lượng hàng lỗi cách ly tại bãi chờ xuất trả NCC (Tăng theo `qty_failed`) |
| `last_updated_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời điểm cập nhật số dư thẻ kho ngay khi có phiếu xuất nhập |
| *Ràng buộc Check* | `CK_Inventory_Min` | Các trường số dư khối lượng tồn kho tuyệt đối không được phép âm |

#### Bảng: `StockIssues` (Phiếu xuất kho cấp phát hàng cho xưởng sản xuất)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `issue_id` | `INT` | PK, Identity | Định danh đơn xuất kho |
| `issue_code` | `NVARCHAR(30)` | Unique, Not Null | Mã số phiếu xuất kho tự động sinh của hệ thống |
| `pr_id` | `INT` | FK, Null | Liên kết ngược về PR gốc phục vụ truy vết chuỗi cung ứng khép kín |
| `dept_id` | `INT` | FK | Phòng ban thụ hưởng tiếp nhận vật tư sử dụng. Liên kết `Departments` |
| `warehouse_keeper_id`|`INT` | FK | Thủ kho xuất hàng thực tế. Liên kết `Users` |
| `receiver_user_id` | `INT` | FK | Đại diện công nhân / kỹ sư của xưởng ký nhận bàn giao hàng. Liên kết `Users` |
| `issued_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời gian thực thi mở cửa kho xuất hàng |

#### Bảng: `StockIssueItems` (Chi tiết vật tư xuất kho và đánh giá chất lượng nội bộ)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `issue_item_id` | `INT` | PK, Identity | Định danh dòng xuất kho |
| `issue_id` | `INT` | FK | Liên kết bảng `StockIssues` |
| `material_id` | `INT` | FK | Liên kết danh mục vật tư chuẩn `Materials` |
| `qty_issued` | `DECIMAL(18,4)`| Not Null | Số lượng khối lượng thực xuất ra khỏi kho khả dụng |
| `quality_rating` | `INT` | Null | Thu thập phản hồi đánh giá chất lượng vật tư thực tế khi đưa vào máy sản xuất (Thang điểm từ 1 đến 5 sao nội bộ v2.0) |
| *Ràng buộc Check* | `CK_StockIssueItems_Qty`| `qty_issued > 0` | Số lượng xuất kho phải lớn hơn 0 |
| *Ràng buộc Check* | `CK_StockIssueItems_Rating`| `quality_rating IS NULL OR (quality_rating >= 1 AND quality_rating <= 5)` |

#### Bảng: `ReturnOrders` (Đơn xuất trả hàng hóa lỗi về phía Nhà cung cấp)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `return_id` | `INT` | PK, Identity | Định danh đơn xuất trả hàng |
| `return_code` | `NVARCHAR(30)` | Unique, Not Null | Mã số phiếu trả hàng của hệ thống |
| `supplier_id` | `INT` | FK | Nhà cung cấp tiếp nhận hàng hoàn trả. Liên kết `Suppliers` |
| `receipt_id` | `INT` | FK | Liên kết nguồn gốc phiếu kho nhận hàng phát hiện lỗi `StockReceipts` |
| `created_by_user_id`| `INT` | FK | Người lập phiếu xuất trả hàng. Liên kết `Users` |
| `return_status` | `NVARCHAR(30)` | Not Null, Default 'DRAFT'| Trạng thái: DRAFT, SENT, RESOLVED |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày tạo đơn trả |

#### Bảng: `ReturnOrderItems` (Chi tiết các mặt hàng xuất trả trích xuất từ kho cách ly)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `return_item_id` | `INT` | PK, Identity | Định danh dòng hàng xuất trả |
| `return_id` | `INT` | FK | Liên kết bảng `ReturnOrders` |
| `material_id` | `INT` | FK | Liên kết danh mục vật tư chuẩn `Materials` |
| `qty_returned` | `DECIMAL(18,4)`| Not Null | Khối lượng thực xuất trả (Trừ vào số dư tồn kho cách ly `qty_quarantine`) |
| `reason` | `NVARCHAR(300)`| Null | Lý do chi tiết từ chối lô hàng đẩy về NCC |
| *Ràng buộc Check* | `CK_ReturnOrderItems_Qty`| `qty_returned > 0` | Số lượng trả hàng phải lớn hơn 0 |

---

### 2.9 Module 8: INVOICE & ĐỐI SOÁT TỰ ĐỘNG 3 CHIỀU (THREE-WAY MATCHING)

#### Bảng: `Invoices` (Hóa đơn tài chính đỏ nhận từ Nhà cung cấp)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `invoice_id` | `INT` | PK, Identity | Định danh hóa đơn hệ thống |
| `invoice_number` | `NVARCHAR(50)` | Not Null | Số hóa đơn đỏ tài chính ghi trên văn bản pháp lý của NCC |
| `invoice_date` | `DATETIME2` | Not Null | Ngày phát hành hóa đơn đỏ ghi trên văn bản |
| `supplier_id` | `INT` | PK, FK | Liên kết danh mục NCC phát hành. Tạo khóa phức chống trùng hóa đơn trùng NCC |
| `ipo_id` | `INT` | FK | Đối ứng đơn đặt mua IPO gốc làm căn cứ đối soát |
| `amount_before_tax`| `DECIMAL(18,2)`| Not Null | Giá trị cốt lõi tiền hàng chưa tính thuế VAT |
| `tax_amount` | `DECIMAL(18,2)`| Not Null | Giá trị tiền thuế VAT đi kèm |
| `total_amount` | `DECIMAL(18,2)`| Not Null | Tổng tiền thanh toán ghi trên hóa đơn đỏ |
| `invoice_pdf_path` | `NVARCHAR(500)`| Null | Đường dẫn lưu trữ file hóa đơn điện tử PDF |
| `matching_status` | `NVARCHAR(30)` | Not Null, Default 'PENDING'| Kết quả chạy thuật toán đối soát tự động: PENDING, MATCHED, MISMATCHED |
| `is_overridden` | `BIT` | Not Null, Default 0 | Cờ ghi nhận phê duyệt bypass (1: Ban giám đốc chấp nhận bỏ qua lỗi chênh lệch đối soát để tiếp tục thanh toán, 0: Khóa kiểm soát) v2.0 |
| `override_by_user_id`|`INT` | FK, Null | Tài khoản lãnh đạo phê duyệt ép trạng thái đối soát. Liên kết `Users` |
| `override_note` | `NVARCHAR(500)`| Null | Giải trình lý do chấp thuận thanh toán lô hàng lỗi lệch giá |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày nhập hóa đơn lên hệ thống |
| *Ràng buộc Check* | `CK_Invoices_Amounts` | Phương trình kế toán bắt buộc: `total_amount = amount_before_tax + tax_amount` |

#### Bảng: `InvoiceMatchingResults` (Bảng chi tiết kết quả bóc tách chạy thuật toán đối soát 3 chiều)
Phân tích so khớp chênh lệch số lượng và đơn giá giữa 3 nguồn: Hóa đơn đỏ NCC cung cấp VS IPO cam kết đặt mua VS Thực tế kho kiểm định đạt chuẩn (`qty_passed`).
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `matching_id` | `INT` | PK, Identity | Định danh kết quả dòng đối soát |
| `invoice_id` | `INT` | FK | Liên kết bảng hóa đơn đỏ nguồn `Invoices` |
| `ipo_item_id` | `INT` | FK | Liên kết thông số chốt giá đơn mua `IPOItems` |
| `receipt_item_id` | `INT` | FK | Liên kết thông số khối lượng kho thực nhận `StockReceiptItems` |
| `qty_invoice` | `DECIMAL(18,4)`| Not Null | Khối lượng kê khai đòi tiền trên hóa đơn đỏ của NCC |
| `qty_received_passed`|`DECIMAL(18,4)`|Not Null | Khối lượng thực tế bãi kho kiểm định đạt chuẩn ký đóng dấu đưa vào sử dụng |
| `price_invoice` | `DECIMAL(18,2)`| Not Null | Đơn giá NCC tính tiền trên hóa đơn đỏ |
| `price_ipo` | `DECIMAL(18,2)`| Not Null | Đơn giá thỏa thuận chốt mua ghi nhận trên IPO |
| `qty_diff` | `DECIMAL(18,4)`| Not Null | Chỉ số chênh lệch khối lượng tính toán: `qty_invoice - qty_received_passed` |
| `price_diff` | `DECIMAL(18,2)`| Not Null | Chỉ số chênh lệch đơn giá mua tính toán: `price_invoice - price_ipo` |
| `is_error` | `BIT` | Not Null, Default 0 | Đánh dấu dòng lỗi nếu biên độ chênh lệch vượt ngưỡng cấu hình hệ thống |
| `log_details_json` | `NVARCHAR(MAX)`| Null | Văn bản chuỗi JSON lưu vết kỹ thuật các bước chạy vòng lặp so khớp của hệ thống v2.0 |

#### Bảng: `PaymentRequests` (Hồ sơ đề nghị Phòng kế toán lập lệnh giải ngân thanh toán)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `payment_req_id` | `INT` | PK, Identity | Định danh đơn yêu cầu thanh toán |
| `payment_req_code` | `NVARCHAR(30)` | Unique, Not Null | Mã số phiếu đề nghị thanh toán tự động sinh của hệ thống |
| `invoice_id` | `INT` | FK | Liên kết hóa đơn đỏ căn cứ pháp lý đã qua đối soát an toàn `Invoices` |
| `applicant_user_id`| `INT` | FK | Nhân viên phòng mua hàng nộp hồ sơ thanh toán. Liên kết `Users` |
| `requested_amount` | `DECIMAL(18,2)`| Not Null | Tổng số tiền đề xuất chi trả kế toán |
| `payment_deadline` | `DATETIME2` | Not Null | Hạn cuối cùng phải giải ngân tiền cho đối tác để tránh phạt hợp đồng |
| `req_status` | `NVARCHAR(30)` | Not Null, Default 'PENDING'| Trạng thái hồ sơ: PENDING, APPROVED, PAID, REJECTED |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày nộp hồ sơ |

#### Bảng: `CreditNotes` (Chứng từ giảm trừ công nợ NCC) [BỔ SUNG v2.1]
*Mục đích nghiệp vụ:* Đáp ứng UC-16C, UC-20 và Khảo sát 6.5 — "Có trường hợp trả hàng hoặc đề nghị hoàn tiền/đổi hàng sau khi đã thanh toán. Quy trình xử lý Debit Note / Credit Note với nhà cung cấp". Phát sinh khi: (1) hàng đã thanh toán bị trả lại NCC; (2) sai lệch đối soát 3 chiều cần khấu trừ; (3) NCC giảm giá hồi tố do chương trình ưu đãi.

| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `credit_note_id` | `INT` | PK, Identity | Định danh chứng từ giảm trừ công nợ |
| `credit_note_code` | `NVARCHAR(30)` | Unique, Not Null | Mã số phiếu nội bộ hệ thống sinh ra (Ví dụ: CN-20260605-001) |
| `credit_note_number` | `NVARCHAR(50)` | Not Null | Số chứng từ pháp lý do NCC phát hành (đối chiếu kế toán đỏ) |
| `supplier_id` | `INT` | FK, Not Null | NCC phát hành chứng từ giảm trừ. Liên kết bảng `Suppliers` |
| `invoice_id` | `INT` | FK, Not Null | Hóa đơn gốc bị điều chỉnh giảm trừ. Liên kết bảng `Invoices` |
| `return_id` | `INT` | FK, Null | Phiếu hoàn trả NCC liên quan (Null nếu credit note phát sinh không do trả hàng). Liên kết `ReturnOrders` |
| `credit_amount_before_tax`| `DECIMAL(18,2)`| Not Null | Giá trị giảm trừ trước thuế |
| `credit_tax_amount`| `DECIMAL(18,2)`| Not Null | Giá trị thuế VAT giảm trừ kèm theo |
| `credit_total_amount`| `DECIMAL(18,2)`| Not Null | Tổng giá trị giảm trừ công nợ |
| `credit_date` | `DATETIME2` | Not Null | Ngày phát hành chứng từ trên giấy tờ pháp lý |
| `reason` | `NVARCHAR(500)`| Not Null | Lý do giảm trừ chi tiết (Phục vụ kiểm toán) |
| `credit_pdf_path` | `NVARCHAR(500)`| Null | Đường dẫn lưu file PDF chứng từ scan |
| `applied_status` | `NVARCHAR(30)` | Not Null, Default 'PENDING'| Trạng thái áp dụng: PENDING (chờ ghi nhận), APPLIED (đã trừ vào kỳ thanh toán), REFUNDED (NCC hoàn tiền mặt) |
| `applied_to_payment_id`| `INT` | FK, Null | ID đơn thanh toán đã được khấu trừ Credit Note này (Null nếu chưa áp dụng) |
| `created_by_user_id`| `INT` | FK, Not Null | Kế toán lập chứng từ. Liên kết `Users` |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày nhập chứng từ vào hệ thống |
| *Ràng buộc Check* | `CK_CreditNotes_Amounts` | `credit_total_amount = (credit_amount_before_tax + credit_tax_amount)` | Phương trình kế toán bắt buộc |
| *Ràng buộc Check* | `CK_CreditNotes_AmountPositive` | `credit_total_amount > 0` | Giá trị giảm trừ phải dương |
| *Ràng buộc Check* | `CK_CreditNotes_Status` | `applied_status IN ('PENDING', 'APPLIED', 'REFUNDED')` | Giới hạn trạng thái |

#### Bảng: `DebitNotes` (Chứng từ NCC điều chỉnh giảm giá sau hóa đơn) [BỔ SUNG v2.1]
*Mục đích nghiệp vụ:* Đáp ứng UC-20 luồng thay thế 6b — "NCC thông báo điều chỉnh giảm giá sau khi đã hóa đơn: tạo Debit Note, điều chỉnh số tiền phải trả". Khác với Credit Note (đến từ phía mua), Debit Note đến từ phía NCC chủ động điều chỉnh giảm số tiền phải thu.

| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `debit_note_id` | `INT` | PK, Identity | Định danh chứng từ |
| `debit_note_code` | `NVARCHAR(30)` | Unique, Not Null | Mã nội bộ hệ thống (Ví dụ: DN-20260610-001) |
| `debit_note_number`| `NVARCHAR(50)` | Not Null | Số chứng từ pháp lý do NCC phát hành |
| `supplier_id` | `INT` | FK, Not Null | NCC phát hành Debit Note. Liên kết `Suppliers` |
| `invoice_id` | `INT` | FK, Not Null | Hóa đơn gốc cần điều chỉnh. Liên kết `Invoices` |
| `debit_amount` | `DECIMAL(18,2)`| Not Null | Số tiền điều chỉnh (giảm giá) |
| `debit_date` | `DATETIME2` | Not Null | Ngày phát hành Debit Note |
| `reason` | `NVARCHAR(500)`| Not Null | Lý do điều chỉnh (Ví dụ: chương trình khuyến mại, sai giá trên hóa đơn gốc) |
| `debit_pdf_path` | `NVARCHAR(500)`| Null | Đường dẫn file PDF chứng từ scan |
| `applied_status` | `NVARCHAR(30)` | Not Null, Default 'PENDING'| Trạng thái: PENDING, APPLIED |
| `applied_to_payment_id`| `INT` | FK, Null | ID đơn thanh toán đã được điều chỉnh |
| `created_by_user_id`| `INT` | FK, Not Null | Kế toán lập chứng từ. Liên kết `Users` |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày nhập chứng từ |
| *Ràng buộc Check* | `CK_DebitNotes_AmountPositive` | `debit_amount > 0` | Số tiền điều chỉnh phải dương |
| *Ràng buộc Check* | `CK_DebitNotes_Status` | `applied_status IN ('PENDING', 'APPLIED')` | Giới hạn trạng thái |

---

### 2.10 Module 9: CẤU HÌNH, THÔNG BÁO HỆ THỐNG & ĐƯỜNG MỜI KIỂM TOÁN (AUDIT TRAIL)

#### Bảng: `SystemConfigs` (Tham số cấu hình động toàn hệ thống)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `config_id` | `INT` | PK, Identity | Định danh tham số cấu hình |
| `config_key` | `NVARCHAR(50)` | Unique, Not Null | Khóa cấu hình (Ví dụ: `OVER_ORDER_TOLERANCE_PERCENT`, `URGENT_PR_ALERT_ROLES`) |
| `config_value_json`| `NVARCHAR(MAX)`| Not Null | Giá trị tham số tổ chức dưới dạng văn bản JSON linh hoạt, tránh hardcode vào mã nguồn v2.0 |
| `description` | `NVARCHAR(300)`| Null | Diễn giải chức năng và cách thức thiết lập tham số |
| `updated_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời gian cập nhật tham số gần nhất |

#### Bảng: `AuditLogs` (Nhật ký lưu vết thao tác - Đường mời kiểm toán an toàn dữ liệu)
*Lưu ý kiến trúc bảo mật:* Bảng dữ liệu này chỉ cho phép quyền đọc (`SELECT`) và ghi thêm dữ liệu mới (`INSERT`), cấm tuyệt đối lệnh sửa (`UPDATE`) và xóa (`DELETE`) mức phân quyền tài khoản Database để phục vụ kiểm toán an ninh thông tin.
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `audit_id` | `INT` | PK, Identity | Định danh dòng nhật ký log |
| `event_type` | `NVARCHAR(50)` | Not Null | Loại hành vi thao tác: 'INSERT', 'UPDATE', 'DELETE', 'OVERRIDE_MATCH' |
| `object_type` | `NVARCHAR(50)` | Not Null | Bảng dữ liệu chịu tác động (Ví dụ: 'PurchaseRequisitions', 'Invoices') |
| `object_id` | `NVARCHAR(50)` | Not Null | Mã số ID của bản ghi chịu tác động |
| `user_id` | `INT` | FK, Null | Tài khoản nhân sự thực thi tác vụ. Liên kết `Users` (Để NULL nếu do hệ thống chạy tự động) |
| `ip_address` | `NVARCHAR(45)` | Null | Địa chỉ mạng IP máy trạm gửi request gửi lệnh hành vi |
| `old_values` | `NVARCHAR(MAX)`| Null | Ảnh chụp toàn bộ trạng thái dữ liệu cũ trước khi tác động (Chuỗi JSON) |
| `new_values` | `NVARCHAR(MAX)`| Null | Ảnh chụp toàn bộ trạng thái dữ liệu mới sau khi tác động thành công (Chuỗi JSON) |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời điểm ghi nhận hành vi tác vụ |

#### Bảng: `EmailTemplates` (Mẫu thông điệp email/in-app dùng chung hệ thống) [BỔ SUNG v2.1]
*Mục đích nghiệp vụ:* Đáp ứng UC-10 — "Tạo email theo template và gửi yêu cầu báo giá kèm link nhập báo giá", UC-05B (alert PR khẩn), UC-13 (thông báo IPO chờ duyệt), UC-23 (cảnh báo sai lệch matching). Đưa các template ra ngoài mã nguồn để Admin/PM có thể chỉnh sửa nội dung (chữ ký công ty, font, từ ngữ ngoại giao) mà không cần deploy lại Backend.

| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `template_id` | `INT` | PK, Identity | Định danh template |
| `template_code` | `NVARCHAR(50)` | Unique, Not Null | Mã hằng số Backend gọi tham chiếu (Ví dụ: `QUOTATION_INVITATION_VN`, `URGENT_PR_ALERT`, `IPO_PENDING_APPROVAL`, `INVOICE_MISMATCH_WARNING`) |
| `template_name` | `NVARCHAR(150)`| Not Null | Tên hiển thị cho Admin trên giao diện cấu hình |
| `channel` | `NVARCHAR(20)` | Not Null | Kênh phát hành: `EMAIL`, `IN_APP`, `SMS` |
| `language` | `NVARCHAR(10)` | Not Null, Default 'vi' | Ngôn ngữ (`vi`, `en`) — cho phép cùng `template_code` có nhiều ngôn ngữ |
| `subject` | `NVARCHAR(300)`| Null | Tiêu đề email/thông báo. Hỗ trợ placeholder `{{variable}}`. Null nếu kênh không yêu cầu (Ví dụ: SMS) |
| `body_html` | `NVARCHAR(MAX)`| Null | Nội dung định dạng HTML cho kênh EMAIL/IN_APP. Hỗ trợ placeholder dạng `{{user_name}}`, `{{pr_code}}`, `{{secure_link}}` |
| `body_plain_text` | `NVARCHAR(MAX)`| Null | Phiên bản plain text (cho email client không render HTML, hoặc cho SMS) |
| `available_placeholders` | `NVARCHAR(MAX)` | Null | Chuỗi JSON liệt kê các placeholder hợp lệ template này hỗ trợ, kèm mô tả. Phục vụ Admin biên soạn không bị sai cú pháp. Ví dụ: `[{"key":"pr_code","desc":"Mã đơn PR"},{"key":"requester_name","desc":"Người tạo PR"}]` |
| `is_system` | `BIT` | Not Null, Default 0 | Cờ phân biệt template hệ thống cốt lõi (1: Không cho phép xóa, chỉ sửa nội dung) vs template do người dùng tạo (0: Cho phép xóa) |
| `is_active` | `BIT` | Not Null, Default 1 | Trạng thái sử dụng (0: Tạm tắt template này, hệ thống fallback sang template default) |
| `last_updated_by_user_id`| `INT` | FK, Null | Tài khoản Admin cập nhật template gần nhất. Liên kết `Users` |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày tạo template |
| `updated_at` | `DATETIME2` | Null | Ngày cập nhật gần nhất |
| *Ràng buộc Unique* | `UQ_EmailTemplates_CodeLang` | `UNIQUE (template_code, language, channel)` | Đảm bảo không trùng template cùng mã + ngôn ngữ + kênh |
| *Ràng buộc Check* | `CK_EmailTemplates_Channel` | `channel IN ('EMAIL', 'IN_APP', 'SMS')` | Giới hạn giá trị kênh hợp lệ |
| *Ràng buộc Check* | `CK_EmailTemplates_BodyRequired` | `body_html IS NOT NULL OR body_plain_text IS NOT NULL` | Bắt buộc có ít nhất 1 nội dung |

**Các `template_code` chuẩn hệ thống cần seed mặc định (Backend dependency):**

| `template_code` | Channel | Use Case kích hoạt | Placeholders chính |
| :--- | :--- | :--- | :--- |
| `QUOTATION_INVITATION_VN` | EMAIL | UC-10 | `{{supplier_name}}`, `{{order_code}}`, `{{deadline}}`, `{{secure_link}}` |
| `QUOTATION_REMINDER_VN` | EMAIL | UC-10 (gửi nhắc nhở) | `{{supplier_name}}`, `{{hours_left}}`, `{{secure_link}}` |
| `URGENT_PR_ALERT` | IN_APP + EMAIL | UC-05B | `{{pr_code}}`, `{{requester_name}}`, `{{urgent_reason}}` |
| `IPO_PENDING_APPROVAL` | IN_APP + EMAIL | UC-13 | `{{ipo_code}}`, `{{total_amount}}`, `{{approval_link}}` |
| `IPO_APPROVED_NOTIFY_BUYER`| IN_APP | UC-13 | `{{ipo_code}}`, `{{approver_name}}` |
| `IPO_REJECTED_NOTIFY_BUYER`| IN_APP + EMAIL | UC-13 | `{{ipo_code}}`, `{{rejection_reason}}` |
| `STOCK_RECEIPT_NOTIFY_DEPT`| IN_APP | UC-16 | `{{material_name}}`, `{{qty_received}}`, `{{dept_name}}` |
| `RETURN_ORDER_TO_SUPPLIER` | EMAIL | UC-16C | `{{supplier_name}}`, `{{return_code}}`, `{{reason}}` |
| `INVOICE_MISMATCH_WARNING` | IN_APP + EMAIL | UC-23 | `{{invoice_number}}`, `{{discrepancy_details}}` |
| `PAYMENT_REQUEST_CREATED` | IN_APP | UC-19 → Kế toán | `{{payment_req_code}}`, `{{amount}}`, `{{deadline}}` |

**Quy tắc vận hành (Backend):** Khi cần gửi thông báo, Backend gọi service `EmailTemplateService.render(template_code, language, context_dict)` để lấy template từ DB, thay placeholder bằng giá trị thực, rồi gửi qua SMTP/Push gateway. Nếu template `is_active = 0` hoặc không tìm thấy, fallback sang template mặc định cùng `template_code` ngôn ngữ `vi`.

#### Bảng: `Notifications` (Hệ thống thông báo đẩy trong ứng dụng)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `notification_id` | `INT` | PK, Identity | Định danh thông báo |
| `recipient_user_id`| `INT` | FK | Tài khoản nhận thông báo. Liên kết bảng `Users` |
| `notification_type`| `NVARCHAR(50)` | Not Null | Phân loại thông báo gửi về: 'PR_ALERT', 'IPO_VERSION', 'MATCH_ERROR' |
| `title` | `NVARCHAR(300)` | Not Null | Tiêu đề hiển thị ngắn gọn của thông báo |
| `body` | `NVARCHAR(1000)`| Not Null | Nội dung thông điệp chi tiết của thông báo |
| `link_url` | `NVARCHAR(500)`| Null | Đường dẫn URL điều hướng nhanh đến màn hình xử lý chứng từ |
| `is_read` | `BIT` | Not Null, Default 0 | Cờ trạng thái xem (0: Chưa đọc, 1: Đã đọc thông báo) |
| `read_at` | `DATETIME2` | Null | Thời điểm kích chuột mở đọc nội dung thông báo |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Thời điểm hệ thống gửi thông báo |
| `email_template_id`| `INT` | FK, Null | Liên kết tới `EmailTemplates` template được dùng để render nội dung (Null nếu render thủ công) |

---

### 2.11 Module 10: SUPPLIER EVALUATION (ĐÁNH GIÁ NHÀ CUNG CẤP ĐỊNH KỲ) [BỔ SUNG v2.1]

*Mục đích nghiệp vụ:* Đáp ứng UC-24 và Khảo sát 2.3 — "Doanh nghiệp có đánh giá/chấm điểm nhà cung cấp định kỳ. Tiêu chí: giao hàng đúng hạn, chất lượng, giá cả, phản hồi. Kết quả ảnh hưởng đến quyết định mua hàng". Module này tách riêng khỏi `Suppliers.rating_score` (chỉ là điểm tổng hợp tĩnh) để lưu vết lịch sử đánh giá theo kỳ, hỗ trợ truy vết và báo cáo xu hướng NCC qua thời gian.

#### Bảng: `SupplierEvaluations` (Bản ghi đánh giá NCC theo kỳ)
| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `evaluation_id` | `INT` | PK, Identity | Định danh bản ghi đánh giá |
| `supplier_id` | `INT` | FK, Not Null | NCC được đánh giá. Liên kết `Suppliers` |
| `period_type` | `NVARCHAR(20)` | Not Null | Loại kỳ đánh giá: `MONTH`, `QUARTER`, `YEAR` |
| `period_value` | `NVARCHAR(20)` | Not Null | Giá trị kỳ (Ví dụ: `2026-Q2`, `2026-06`, `2026`) |
| `period_start_date`| `DATETIME2` | Not Null | Ngày bắt đầu kỳ đánh giá (Phục vụ truy vấn giao dịch trong khoảng) |
| `period_end_date` | `DATETIME2` | Not Null | Ngày kết thúc kỳ đánh giá |
| `total_score` | `DECIMAL(5,2)` | Not Null | Điểm tổng cuối cùng sau khi áp trọng số (Thang 0-100) |
| `rank` | `NVARCHAR(20)` | Not Null | Xếp hạng: `GOLD` (≥85), `SILVER` (70-84), `BRONZE` (50-69), `WARNING` (<50). Ngưỡng cấu hình trong `SystemConfigs` |
| `subjective_comment`| `NVARCHAR(1000)`| Null | Nhận xét chủ quan của Trưởng phòng MH (Ngoài các chỉ số tự động) |
| `is_finalized` | `BIT` | Not Null, Default 0 | Cờ chốt bản đánh giá (1: Đã chốt, không cho sửa; 0: Đang nháp) |
| `evaluator_user_id`| `INT` | FK, Not Null | Trưởng phòng MH thực hiện đánh giá. Liên kết `Users` |
| `created_at` | `DATETIME2` | Not Null, Default GETDATE() | Ngày tạo bản đánh giá |
| `finalized_at` | `DATETIME2` | Null | Ngày chốt bản đánh giá (Sau khi chốt mới ảnh hưởng đến `Suppliers.rating_score`) |
| *Ràng buộc Unique* | `UQ_SupplierEvaluations_Period` | `UNIQUE (supplier_id, period_type, period_value)` | Không cho phép trùng đánh giá cùng kỳ cho cùng NCC |
| *Ràng buộc Check* | `CK_SupplierEvaluations_Score` | `total_score >= 0 AND total_score <= 100` | Điểm tổng nằm trong thang chuẩn |
| *Ràng buộc Check* | `CK_SupplierEvaluations_Rank` | `rank IN ('GOLD', 'SILVER', 'BRONZE', 'WARNING')` | Giới hạn giá trị xếp hạng |
| *Ràng buộc Check* | `CK_SupplierEvaluations_PeriodType` | `period_type IN ('MONTH', 'QUARTER', 'YEAR')` | Giới hạn giá trị kỳ |
| *Ràng buộc Check* | `CK_SupplierEvaluations_DateRange` | `period_end_date > period_start_date` | Ngày kết thúc lớn hơn ngày bắt đầu |

#### Bảng: `SupplierEvaluationCriteria` (Chi tiết điểm từng tiêu chí)
*Tách riêng để hỗ trợ thêm/sửa tiêu chí đánh giá linh hoạt (không cần migration schema khi thêm tiêu chí mới).*

| Tên cột | Kiểu dữ liệu | Thuộc tính | Mô tả / Ràng buộc |
| :--- | :--- | :--- | :--- |
| `criteria_id` | `INT` | PK, Identity | Định danh dòng tiêu chí |
| `evaluation_id` | `INT` | FK, Not Null | Liên kết bảng `SupplierEvaluations` |
| `criteria_code` | `NVARCHAR(50)` | Not Null | Mã tiêu chí (Ví dụ: `DELIVERY_ON_TIME`, `QUALITY_AVERAGE`, `PRICE_COMPETITIVENESS`, `RESPONSIVENESS`, `SUBJECTIVE_SCORE`) |
| `criteria_name` | `NVARCHAR(150)`| Not Null | Tên hiển thị tiêu chí (Ví dụ: "Tỷ lệ giao hàng đúng hạn") |
| `raw_score` | `DECIMAL(5,2)` | Not Null | Điểm thô của tiêu chí trước trọng số (Thang 0-100) |
| `weight` | `DECIMAL(5,4)` | Not Null | Trọng số áp dụng (0.00 - 1.00, ví dụ 0.30 = 30%) |
| `weighted_score` | `DECIMAL(7,4)` | Not Null | Điểm sau trọng số = `raw_score * weight` (Backend tự tính) |
| `data_source_json`| `NVARCHAR(MAX)`| Null | Chuỗi JSON ghi vết nguồn dữ liệu tính điểm (Ví dụ: `{"total_orders":12, "on_time":10, "rate":0.833}`). Phục vụ giải trình khi NCC khiếu nại điểm số |
| `notes` | `NVARCHAR(500)`| Null | Ghi chú thủ công của người đánh giá cho tiêu chí này |
| *Ràng buộc Unique* | `UQ_EvalCriteria_EvalCode` | `UNIQUE (evaluation_id, criteria_code)` | Không trùng tiêu chí trong cùng 1 bản đánh giá |
| *Ràng buộc Check* | `CK_EvalCriteria_RawScore` | `raw_score >= 0 AND raw_score <= 100` | Điểm thô trong thang chuẩn |
| *Ràng buộc Check* | `CK_EvalCriteria_Weight` | `weight >= 0 AND weight <= 1` | Trọng số trong khoảng [0,1] |

**Quy tắc vận hành (Backend):**
- Khi tạo `SupplierEvaluations` ở trạng thái `is_finalized = 0`, người dùng vẫn có thể sửa các dòng `SupplierEvaluationCriteria`. Backend tự tính `total_score = SUM(weighted_score)` mỗi lần cập nhật.
- Khi gọi API "finalize", Backend kiểm tra `SUM(weight) = 1.00` (tổng trọng số = 100%), chuyển `is_finalized = 1`, và **cập nhật ngược lại** `Suppliers.rating_score` theo công thức trung bình các kỳ gần nhất (cấu hình tại `SystemConfigs.SUPPLIER_RATING_AVERAGE_PERIODS`).
- Nếu NCC bị xếp `WARNING` 2 kỳ liên tiếp, Backend tự động tạo Notification cho Trưởng phòng MH gợi ý chuyển trạng thái `Suppliers.is_active = 0` (Tạm dừng).

---

## 3. Bản Đăng Ký Chỉ Mục Tăng Tốc Truy Vấn (Indexes Specification)

Nhằm đảm bảo hệ thống vận hành mượt mà, phản hồi nhanh chóng dưới 500ms khi quy mô dữ liệu phình to ở môi trường sản xuất thực tế, database thiết lập danh sách các chỉ mục phi cụm (`Nonclustered Index`) tối ưu cho các câu lệnh truy vấn tìm kiếm tần suất cao:

```sql
-- 1. Chỉ mục tối ưu hóa hiệu năng tìm kiếm kiểm toán nhanh theo dòng thời gian bản ghi
CREATE NONCLUSTERED INDEX IX_AuditLogs_performance 
ON AuditLogs(object_type, object_id, created_at);

-- 2. Chỉ mục tối ưu hóa truy vấn màn hình thông báo chưa đọc của người dùng hiện hành
CREATE NONCLUSTERED INDEX IX_Notifications_Unread 
ON Notifications(recipient_user_id, is_read);

-- 3. Chỉ mục tăng tốc độ gom hàng và lọc trạng thái xử lý các dòng mặt hàng PR
CREATE NONCLUSTERED INDEX IX_PRItems_Lookup 
ON PRItems(pr_id, item_status);

-- 4. Chỉ mục tối ưu hóa truy vấn bóc tách lịch sử, luôn quét phiên bản IPO hiện hành đang có hiệu lực
CREATE NONCLUSTERED INDEX IX_IPO_LatestVersion 
ON IPOs(ipo_code, is_latest, ipo_status);

-- 5. Chỉ mục hỗ trợ phân hệ Kế toán lọc nhanh các hóa đơn lỗi chưa xử lý đối soát xong
CREATE NONCLUSTERED INDEX IX_InvoiceMatching_Run 
ON Invoices(ipo_id, matching_status);

-- ===== Index bổ sung v2.1 cho 4 bảng mới =====

-- 6. Chỉ mục truy vấn nhanh lịch sử các phiên bản báo giá theo Quotation gốc
CREATE NONCLUSTERED INDEX IX_QuotationVersions_Current
ON QuotationVersions(quotation_id, is_current, version_number);

-- 7. Chỉ mục tăng tốc truy vấn công nợ chứng từ Credit Note theo NCC và trạng thái áp dụng
CREATE NONCLUSTERED INDEX IX_CreditNotes_SupplierStatus
ON CreditNotes(supplier_id, applied_status, credit_date);

-- 8. Chỉ mục Debit Note song song theo NCC
CREATE NONCLUSTERED INDEX IX_DebitNotes_SupplierStatus
ON DebitNotes(supplier_id, applied_status, debit_date);

-- 9. Chỉ mục đánh giá NCC theo kỳ (phục vụ báo cáo xu hướng)
CREATE NONCLUSTERED INDEX IX_SupplierEvaluations_Period
ON SupplierEvaluations(supplier_id, period_type, period_value, is_finalized);

-- 10. Chỉ mục Email Templates lookup theo template_code + ngôn ngữ + kênh (hot path khi Backend render thông báo)
CREATE NONCLUSTERED INDEX IX_EmailTemplates_Lookup
ON EmailTemplates(template_code, language, channel, is_active);
```

---

## 4. Đặc Tả Tối Ưu Tìm Kiếm Văn Bản Nâng Cao (Full-Text Search Engine)

Đối với nghiệp vụ tìm kiếm tự do vật tư danh mục gốc của nhân viên vận hành nhà máy (Ví dụ gõ tìm chuỗi ký tự nằm giữa văn bản như `"Thép Hòa Phát phi 14"` hoặc `"Ống nhựa Bình Minh 27"`), việc sử dụng câu lệnh tiêu chuẩn dạng `LIKE '%keyword%'` sẽ ép hệ thống chạy quét toàn bảng (`Table Scan`), gây tắc nghẽn tài nguyên CPU máy chủ cơ sở dữ liệu. 

Hệ thống triển khai giải pháp cấu hình **Full-Text Index** trực tiếp trên hệ quản trị MSSQL Server:

1. **Khởi tạo tài nguyên lưu trữ:** Đăng ký một danh mục catalog chuyên dụng cho bài toán mua hàng mang tên `ProcurementFTCatalog`.
2. **Cấu hình chỉ mục văn bản nâng cao:** Thiết lập Full-Text Index trên bảng danh mục gốc `Materials` cho hai trường thông tin văn bản chính: `material_name` và `description`.
3. **Đồng bộ ngôn ngữ:** Chỉ định rõ mã nhận diện bộ phân tách từ khóa là **Ngôn ngữ Tiếng Việt (Mã quốc gia: 1066)** kèm theo danh sách từ dừng hệ thống (`STOPLIST = SYSTEM`) để xử lý chuẩn xác cấu trúc dấu thanh, từ ngữ ngữ pháp Tiếng Việt.

*Cú pháp Backend khuyên dùng thay thế câu lệnh LIKE:*
```sql
SELECT * FROM Materials 
WHERE CONTAINS(material_name, '"*Thép*" AND "*14*"');
```

---
## 5. Quy Tắc Toàn Vẹn & An Ninh Dữ Liệu Tối Thượng Mức Database

1. **Tuyệt đối không sử dụng Soft Delete cho các bảng Master Data:** Mọi trạng thái dừng hoạt động phải được chuyển dịch qua trường cờ kiểm soát `is_active = 0`. Các bản ghi liên quan đến số liệu tài chính hóa đơn, chứng từ kế toán tuyệt đối không được phép xóa vật lý (`DELETE`) khỏi database để bảo vệ tính toàn vẹn dữ liệu báo cáo thuế lịch sử.
2. **Cân bằng phương trình số lượng kho:** Bất kỳ thao tác cộng/trừ số dư thẻ kho trong bảng `Inventory` tại các trường `qty_on_hand`, `qty_available`, `qty_quarantine` bắt buộc phải được bọc trong một phiên giao dịch cơ sở dữ liệu duy nhất (`DATABASE TRANSACTION`) có cơ chế kiểm soát lỗi `ROLLBACK` toàn phần nếu một trong các tiến trình tính toán bị ngắt quãng hoặc báo lỗi logic.
3. **An toàn bảo mật phân quyền ứng dụng:** Mã nguồn Backend kết nối xuống Database sử dụng tài khoản SQL Server phân quyền hạn chế (Cấm quyền cấu hình cấu trúc bảng `ALTER`/`DROP` trong giờ vận hành hệ thống). Riêng bảng nhật ký `AuditLogs` được cấu hình chặn cứng bằng Trigger ngăn chặn mọi tác vụ sửa đổi dữ liệu từ bên ngoài.
4. **Toàn vẹn lịch sử báo giá (Quotation versioning) — v2.1:** Mọi thao tác cập nhật bản ghi `Quotations` từ portal NCC bắt buộc đi qua stored procedure `sp_SubmitQuotationVersion` bọc kín trong transaction để đảm bảo: (a) Sinh phiên bản mới trong `QuotationVersions` với snapshot JSON đầy đủ, (b) Hạ cờ `is_current = 0` các phiên bản cũ, (c) Cập nhật `Quotations` với giá mới nhất. Nếu một trong 3 bước fail, rollback toàn phần để tránh tình trạng "mất bản ghi lịch sử" hoặc "có 2 phiên bản đều `is_current = 1`".
5. **Toàn vẹn công nợ Credit/Debit Note — v2.1:** Trường `credit_total_amount` và `debit_amount` không bao giờ được sửa sau khi `applied_status` chuyển sang `APPLIED`. Backend bắt buộc kiểm tra ràng buộc này trước khi gọi `UPDATE` (kiểm tra song song với CHECK constraint mức DB). Khi áp dụng Credit/Debit Note vào `PaymentRequests`, phải bọc trong transaction để đảm bảo `requested_amount` của PaymentRequest được tính lại chính xác.
6. **Bảo vệ điểm xếp hạng NCC — v2.1:** Trường `Suppliers.rating_score` không được cập nhật trực tiếp từ bất kỳ Backend service nào. Chỉ duy nhất stored procedure `sp_FinalizeSupplierEvaluation` được phép cập nhật trường này, và chỉ sau khi `SupplierEvaluations.is_finalized` chuyển từ 0 → 1. Sau khi `is_finalized = 1`, các bản ghi `SupplierEvaluations` và `SupplierEvaluationCriteria` của bản đánh giá đó tuyệt đối không được sửa hoặc xóa (chỉ cho phép tạo bản đánh giá kỳ mới).
7. **Toàn vẹn template thông báo — v2.1:** Bảng `EmailTemplates` với cờ `is_system = 1` không được phép `DELETE` ở mức database (chặn bằng Trigger). Admin chỉ được sửa nội dung `subject`, `body_html`, `body_plain_text` và chuyển `is_active`. Đảm bảo các tham chiếu hằng số từ Backend (`template_code` như `URGENT_PR_ALERT`) không bao giờ bị broken reference gây crash khi gửi thông báo.
