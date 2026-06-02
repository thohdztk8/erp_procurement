# TÀI LIỆU ĐẶC TẢ YÊU CẦU PHẦN MỀM (SRS)

**Dự án:** Hệ Thống Quản Lý Mua Hàng Doanh Nghiệp Sản Xuất

**Phiên bản:** 2.0

**Ngày lập:** 25/05/2026

**Tham chiếu:** URD v1.0, Use-Case Document v2.0, Thiết kế DB v2.0

**Công nghệ nền tảng:** Python (Django) | Microsoft SQL Server (MSSQL) | Frontend (ReactJS)

**Triển khai:** sử dụng docker (compose) để build up hệ thống

## 1. Tổng Quan Hệ Thống

### 1.1 Mục Tiêu & Phạm Vi

Tài liệu SRS này đặc tả chi tiết các yêu cầu chức năng và phi chức năng cho Hệ thống Quản lý Mua hàng nhằm số hóa toàn diện chuỗi cung ứng nội bộ của doanh nghiệp sản xuất. Hệ thống thay thế hoàn toàn các quy trình thủ công (Excel, Email, Giấy tờ), kết nối đồng bộ dữ liệu giữa 5 bộ phận:  **Sản xuất/Yêu cầu** ,  **Phòng Mua hàng** ,  **Kho vận** ,  **Kế toán** , và  **Ban Giám đốc** .

### 1.2 Mô Hình Kiến Trúc & Luồng Nghiệp Vụ Tổng Quát

Hệ thống vận hành theo luồng vòng đời chứng từ khép kín:

$$
\text{Đề xuất PR} \longrightarrow \text{Gom Cart \& Tạo Order} \longrightarrow \text{Mời Báo Giá (Portal)} \longrightarrow \text{Chốt Đơn IPO} \longrightarrow \text{Kiểm Định IQC \& Nhập Kho} \longrightarrow \text{Đối Soát 3 Chiều} \longrightarrow \text{Thanh Toán}
$$

## 2. Yêu Cầu Chức Năng Chi Tiết (Functional Requirements)

### 2.1 Module 1: Quản Trị Hệ Thống & Phân Quyền (AUTH)

* **Mã yêu cầu:** `REQ-AUTH-01` (Phân quyền RBAC động)
  * **Mô tả:** Hệ thống kiểm soát truy cập dựa trên vai trò thông qua ma trận `Users - Roles - Permissions` liên kết chặt chẽ theo `Branches` và `Departments`.
  * **Quy tắc nghiệp vụ:** * Mật khẩu phải được băm một chiều bằng thuật toán an toàn (BCrypt/Argon2) trước khi lưu vào `password_hash`.
    * Tài khoản bị khóa tạm thời (`locked_until`) trong 15 phút nếu số lần đăng nhập sai liên tiếp (`login_fail_count`) vượt quá 5 lần.
* **Mã yêu cầu:** `REQ-AUTH-02` (Đường mời kiểm toán - Audit Trail)
  * **Mô tả:** Mọi hành vi ghi/sửa/xóa dữ liệu phải ghi nhận tự động vào `AuditLogs`.
  * **Quy tắc hệ thống:** Tầng Database cấm tuyệt đối lệnh `UPDATE` và `DELETE` vật lý đối với bảng `AuditLogs`. Ghi nhận toàn vẹn ảnh chụp trạng thái cũ (`old_values`) và mới (`new_values`) dưới dạng JSON.

### 2.2 Module 2: Quản Lý Yêu Cầu Mua Hàng (PR)

* **Mã yêu cầu:** `REQ-PR-01` (Khởi tạo Đề xuất PR Thường & Khẩn)
  * **Mô tả:** Trưởng bộ phận khởi tạo yêu cầu vật tư cho xưởng sản xuất.
  * **Quy tắc nghiệp vụ:**
    * **Kiểm tra loại trừ chéo vật tư:** Dòng hàng phải chọn từ danh mục chuẩn (`material_id`) **HOẶC** nhập tay text tự do (`material_name_other`) nếu là hàng ngoài danh mục. Không được trống cả hai và không được điền đồng thời cả hai.
    * **Cơ chế Đơn Khẩn (Urgent):** Nếu `priority_level = 'URGENT'`, hệ thống bắt buộc người dùng nhập trường `urgent_reason` (Lý do khẩn) và `urgency_impact` (Tác động vận hành), đồng thời kích hoạt thông báo đẩy thời gian thực đến cấp phê duyệt.

### 2.3 Module 3: Ma Trận Phê Duyệt Động (APPROVAL MATRIX)

* **Mã yêu cầu:** `REQ-APP-01` (Phê duyệt chứng từ tuyến tính theo hạn mức)
  * **Mô tả:** Khi PR hoặc IPO được chuyển sang trạng thái `PENDING`, hệ thống tự động đối chiếu tổng tiền chứng từ với cấu hình trong `ApprovalWorkflows` để sinh tuyến trình các bước duyệt `ApprovalWorkflowSteps`.
  * **Quy tắc nghiệp vụ:** * Chứng từ phải được duyệt tuần tự theo thứ tự tăng dần của `step_sequence`.
    * Tại bất kỳ bước nào, nếu người duyệt chọn `REJECTED`, toàn bộ chứng từ chuyển ngay về trạng thái thất bại, bắt buộc nhập `comment` giải trình lý do từ chối.

### 2.4 Module 4: Gom Giỏ Hàng & Mời Thầu Báo Giá (CART & QUOTATION)

* **Mã yêu cầu:** `REQ-QUO-01` (Gom hàng tập trung - Carts & Orders)
  * **Mô tả:** Nhân viên mua hàng gom nhiều dòng `PRItems` có cùng nhóm hàng vào một `Carts` để tối ưu khối lượng đặt mua (`qty_total_ordered`), tăng vị thế đàm phán thương lượng giá với đối tác.
* **Mã yêu cầu:** `REQ-QUO-02` (Mã khóa Token bảo mật Portal Nhà cung cấp)
  * **Mô tả:** Khi phát hành yêu cầu báo giá, hệ thống gửi email tự động tới các NCC phối thuộc (`OrderSuppliers`) chứa đường dẫn định danh duy nhất.
  * **Quy tắc bảo mật:** Link truy cập chứa mã Token được băm bằng thuật toán một chiều SHA-256 (`QuotationTokens.token`). Link tự động vô hiệu hóa nếu vượt quá `expires_at` hoặc ngay sau khi nhà cung cấp nhấn nút Submit báo giá chốt thầu (`is_used = 1`).

### 2.5 Module 5: Quản Lý Đơn Đặt Hàng Nội Bộ Đa Phiên Bản (IPO)

* **Mã yêu cầu:** `REQ-IPO-01` (Quản lý biến động số lượng & đơn giá)
  * **Mô tả:** Đơn đặt hàng IPO lưu vết tất cả các lần chỉnh sửa đổi trả do đàm phán hoặc thay đổi kế hoạch sản xuất.
  * **Quy tắc toàn vẹn:** Hệ thống không ghi đè dữ liệu cũ. Khi có chỉnh sửa, bản ghi hiện tại chuyển cờ hiệu lực `is_latest = 0`, hệ thống sinh ra một bản ghi mới tăng tịnh tiến trường số hiệu phiên bản (`version = version + 1`) và bật cờ `is_latest = 1`.
  * **Kiểm soát khối lượng tối đa:** Hệ thống chặn cứng tại tầng database không cho phép tổng số lượng gom hàng lên đơn IPO lũy tiến vượt quá khối lượng phòng ban đề xuất ban đầu trên đơn PR gốc:
    $$
    \sum \text{qty\_final}_{\text{IPO}} \le \text{qty\_requested}_{\text{PR}}
    $$

### 2.6 Module 6: Quản Lý Kiểm Định IQC & Nhận Kho (WAREHOUSE)

* **Mã yêu cầu:** `REQ-WH-01` (Phân loại chất lượng đầu vào IQC)
  * **Mô tả:** Thủ kho nhận hàng giao tới bãi dựa trên IPO đã được phê duyệt (`APPROVED`). Tiến hành cân đo kiểm đếm và phân loại chất lượng vật lý.
  * **Phương trình cân bằng khối lượng kho:** Hệ thống bắt buộc tuân thủ nghiêm ngặt công thức kiểm toán:
    $$
    \text{qty\_received} = \text{qty\_passed} + \text{qty\_failed}
    $$
  * **Quy tắc minh chứng ảnh lỗi:** Nếu xuất hiện số lượng hàng lỗi, hỏng, sai quy cách (`qty_failed > 0`), hệ thống bắt buộc nhân viên kiểm định phải đăng tải hình ảnh hiện trường thực tế, lưu đường dẫn dưới dạng chuỗi mảng JSON vào cột `photo_paths`. Chấm dứt tình trạng khuyết bằng chứng khi phạt trừ tiền NCC.
  * **Cập nhật số dư Inventory:** Số lượng đạt chuẩn (`qty_passed`) được cộng vào tồn kho khả dụng cấp phát (`qty_available`), số lượng lỗi (`qty_failed`) được đẩy vào kho cách ly biệt trữ (`qty_quarantine`) chờ xuất trả.

### 2.7 Module 7: Đối Soát Tự Động 3 Chiều & Thanh Toán (INVOICE & 3-WAY MATCHING)

* **Mã yêu cầu:** `REQ-INV-01` (Thuật toán kiểm soát sai lệch 3 chiều)
  * **Mô tả:** Khi kế toán nhập hóa đơn đỏ (`Invoices`) từ NCC, hệ thống tự động kích hoạt vòng lặp chạy đối chiếu chéo thông tin trên 3 nguồn dữ liệu độc lập:

    1. **Hóa đơn tài chính:** Số lượng (`qty_invoice`) & Đơn giá đòi tiền (`price_invoice`).
    2. **Đơn đặt hàng gốc:** Đơn giá cam kết ký kết trên đơn (`price_ipo`).
    3. **Phiếu nhập kho vật lý:** Số lượng thực tế kiểm định đạt chuẩn nhập kho (`qty_received_passed`).
  * **Tính toán sai lệch kỹ thuật:**

    $$
    \text{qty\_diff} = \text{qty\_invoice} - \text{qty\_received\_passed}
    $$

    $$
    \text{price\_diff} = \text{price\_invoice} - \text{price\_ipo}
    $$
  * **Cơ chế Phê duyệt Bypass lỗi (Override):** Nếu phát sinh sai lệch (`is_error = 1`), hệ thống khóa luồng thanh toán chuyển trạng thái `MISMATCHED`. Chỉ duy nhất cấp Lãnh đạo tối cao (Ban giám đốc) mới có thẩm quyền nhấn nút ghi đè (`is_overridden = 1`), ép hệ thống duyệt chi kèm văn bản giải trình lý do (`override_note`) lưu vết kiểm toán.

## 3. Bản Bản Đăng Ký Giao Diện Chương Trình Ứng Dụng (API Endpoints)

Các API được thiết kế theo chuẩn kiến trúc RESTful, dữ liệu trao đổi qua định dạng JSON, bắt buộc đính kèm chuỗi JWT Token tại Header của HTTP Request phục vụ xác thực vai trò người dùng.

| **Phương thức HTTP** | **Đường dẫn API Endpoints** | **Phân quyền truy cập** | **Mô tả chức năng nghiệp vụ**                                             |
| ----------------------------- | ------------------------------------- | -------------------------------- | ------------------------------------------------------------------------------------- |
| `POST`                      | `/api/v2/auth/login`                | Công khai                       | Đăng nhập hệ thống, cấp chuỗi mã khóa xác thực JWT.                        |
| `POST`                      | `/api/v2/pr/create`                 | Trưởng bộ phận               | Khởi tạo đơn yêu cầu mua hàng PR (Thường / Khẩn).                           |
| `GET`                       | `/api/v2/pr/pending-list`           | Cấp phê duyệt                 | Lấy danh sách chứng từ PR đang chờ tài khoản hiện hành phê duyệt.         |
| `POST`                      | `/api/v2/pr/approve`                | Cấp phê duyệt                 | Nhấn nút Phê duyệt / Từ chối đơn PR hiện hành.                              |
| `POST`                      | `/api/v2/cart/add-items`            | Nhân viên mua hàng            | Trích xuất dòng hàng PR hợp lệ đưa vào giỏ hàng điều phối.              |
| `POST`                      | `/api/v2/quotation/invite`          | Nhân viên mua hàng            | Đóng gói đơn hàng, sinh mã Token SHA-256 và gửi Mail mời thầu.             |
| `POST`                      | `/api/v2/vendor-portal/submit`      | Nhà cung cấp bên ngoài       | Cổng Portal nhận đơn giá chào thầu và tự động khóa Token.                 |
| `POST`                      | `/api/v2/ipo/create-version`        | Nhân viên mua hàng            | Chốt phương án nhà thầu, phát hành đơn đặt hàng IPO phiên bản mới.    |
| `POST`                      | `/api/v2/warehouse/receipt`         | Thủ kho                         | Lập phiếu nhập kho kiểm định, phân loại hàng đạt/lỗi kèm JSON ảnh.      |
| `POST`                      | `/api/v2/invoice/verify-matching`   | Kế toán viên                  | Kích hoạt thuật toán đối soát 3 chiều, tính toán biên độ sai lệch giá. |

## 4. Yêu Cầu Phi Chức Năng (Non-Functional Requirements)

### 4.1 Hiệu Năng Vận Hành (Performance)

* **Thời gian phản hồi hệ thống (Latency):** 95% các thao tác truy vấn dữ liệu báo cáo, tìm kiếm danh mục vật tư trên giao diện web phải trả về kết quả dưới  **500ms** .
* **Giải pháp tăng tốc dữ liệu:** * Áp dụng các phi chỉ mục (`Nonclustered Index`) chuyên dụng cho các trường tìm kiếm tần suất cao như kiểm tra phiên bản IPO hiện hành đang hoạt động (`is_latest`), kiểm tra danh sách thông báo chưa đọc (`is_read`).
  * Triển khai công cụ **Full-Text Index (Vietnamese - Code 1066)** đối với các trường chuỗi văn bản dài tự do như `material_name` và `description` của danh mục gốc `Materials`, triệt tiêu hoàn toàn các câu lệnh quét quét sạch dữ liệu bảng dạng `LIKE '%keyword%'`.

### 4.2 Tính Sẵn Sàng & Khả Năng Mở Rộng (Availability & Scalability)

* **Thời gian hoạt động (Uptime):** Hệ thống triển khai trên hạ tầng điện toán đám mây (Cloud), cam kết chỉ số sẵn sàng dịch vụ tối thiểu đạt **99.9%** (SLA 24/7).
* **Tải trọng thiết kế:** Hệ thống đáp ứng xử lý luồng dữ liệu biến động từ **50 đến 500 đơn hàng** quy mô lớn phát sinh mỗi tháng, sẵn sàng mở rộng quy mô đồng thời khi doanh nghiệp xây dựng thêm các nhà máy mới.

### 4.3 An Ninh & Bảo Mật Tuyệt Đối (Security & Integrity)

* **Toàn vẹn số liệu tài chính:** Database cấu hình chặn cứng, cấm tuyệt đối lệnh xóa vật lý (`Soft Delete Only`) đối với các bảng danh mục Master Data hoặc thông tin hóa đơn chứng từ kế toán đỏ. Trạng thái bản ghi điều khiển thông qua cờ `is_active = 0`.
* **Phiên giao dịch nguyên tử (Database Transaction):** Tiến trình tính toán tăng/giảm số dư khối lượng hàng hóa trong bảng thẻ kho `Inventory` bắt buộc phải được bọc kín trong cấu trúc Transaction mức thấp nhất. Nếu xảy ra lỗi nghẽn mạng ở bất cứ dòng lệnh nào, hệ thống phải tự động thực thi lệnh `ROLLBACK` trạng thái ban đầu, ngăn chặn triệt để lỗi sai lệch số dư tồn kho ảo.
* **Bảo mật lớp ứng dụng:** Chặn các lỗi tấn công tiêm mã độc SQL Injection bằng cách bắt buộc sử dụng cơ chế truyền tham số an toàn (`Parameterized Queries`) hoặc tầng giao tiếp đối tượng ORM (SQLAlchemy / Django ORM) ở tầng Backend.
