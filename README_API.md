# Tài liệu Danh sách API và Ánh xạ Giao diện (Frontend Views Mapping)

Tài liệu này cung cấp toàn bộ danh mục các nhóm API của hệ thống Django Backend (phiên bản v2) và hướng dẫn cấu trúc các màn hình Frontend Vue 3 tương ứng đã được xây dựng.

---

## 1. Nhóm API Hệ thống & Xác thực (Authentication)
* **Màn hình Frontend tương ứng:** [LoginView.vue](file:///Users/quangsangle.hn/Desktop/erp_procurement/frontend/src/views/LoginView.vue) và Quản lý Profile [ProfileView.vue](file:///Users/quangsangle.hn/Desktop/erp_procurement/frontend/src/views/ProfileView.vue)
* **Tiền tố đường dẫn (Prefix):** `/api/v2/auth/`

| Phương thức | Đường dẫn API | Chức năng | Ghi chú |
| :--- | :--- | :--- | :--- |
| **POST** | `/api/v2/auth/login` | Đăng nhập tài khoản | Trả về Access Token và Refresh Token |
| **POST** | `/api/v2/auth/refresh` | Làm mới Access Token | Khi token hiện tại hết hạn |
| **POST** | `/api/v2/auth/logout` | Đăng xuất tài khoản | Xóa phiên đăng nhập trên hệ thống |
| **GET** | `/api/v2/auth/profile` | Lấy thông tin tài khoản | Trả về thông tin chi tiết và quyền (permissions) |
| **GET** | `/api/v2/health/` | Kiểm tra trạng thái hệ thống | Health check độc lập |

---

## 2. Nhóm API Dữ liệu gốc (Master Data)
* **Màn hình Frontend tương ứng:** [MasterDataView.vue](file:///Users/quangsangle.hn/Desktop/erp_procurement/frontend/src/views/MasterDataView.vue)
* **Tiền tố đường dẫn (Prefix):** `/api/v2/master/`

| Phương thức | Đường dẫn API | Chức năng | Ghi chú |
| :--- | :--- | :--- | :--- |
| **GET** | `/api/v2/master/materials` | Lấy danh mục Vật tư | Danh sách mã vật tư, tên, đơn vị, giá tham chiếu |
| **GET** | `/api/v2/master/materials/<id>` | Chi tiết Vật tư | Thông tin cụ thể của 1 vật tư |
| **GET** | `/api/v2/master/suppliers` | Lấy danh sách Nhà cung cấp | Danh sách các đối tác cung ứng |
| **GET** | `/api/v2/master/suppliers/<id>` | Chi tiết Nhà cung cấp | Địa chỉ, mã số thuế, thông tin liên lạc đối tác |
| **GET** | `/api/v2/master/approval-workflows` | Lấy luồng phê duyệt | Các bước và cấp độ duyệt tài liệu |
| **GET** | `/api/v2/master/configs` | Cấu hình hệ thống | Tham số cấu hình ERP |

---

## 3. Nhóm API Yêu cầu Mua sắm (Purchase Request - PR)
* **Màn hình Frontend tương ứng:** Dashboard chính [HomeView.vue](file:///Users/quangsangle.hn/Desktop/erp_procurement/frontend/src/views/HomeView.vue)
* **Tiền tố đường dẫn (Prefix):** `/api/v2/pr/`

| Phương thức | Đường dẫn API | Chức năng | Ghi chú |
| :--- | :--- | :--- | :--- |
| **POST** | `/api/v2/pr/create` | Tạo mới yêu cầu mua sắm PR | Thêm vật tư cần mua vào đơn nháp (Draft) |
| **GET** | `/api/v2/pr/` | Lấy danh sách PR | Xem các đơn PR của tôi hoặc bộ phận |
| **GET** | `/api/v2/pr/<id>` | Lấy chi tiết đơn PR | Chi tiết vật tư, trạng thái duyệt, lịch sử phê duyệt |
| **POST** | `/api/v2/pr/<id>/submit` | Gửi duyệt PR | Chuyển trạng thái từ DRAFT sang PENDING |
| **GET** | `/api/v2/pr/pending-list` | Lấy danh sách PR chờ duyệt | Dành cho cấp quản lý có quyền phê duyệt |
| **POST** | `/api/v2/pr/approve` | Phê duyệt hoặc từ chối PR | Gửi quyết định phê duyệt (APPROVED/REJECTED) kèm ý kiến |

---

## 4. Nhóm API Giỏ hàng & Đơn mua hàng (Cart & PO)
* **Màn hình Frontend tương ứng:** [CartOrderView.vue](file:///Users/quangsangle.hn/Desktop/erp_procurement/frontend/src/views/CartOrderView.vue)
* **Tiền tố đường dẫn (Prefix):** `/api/v2/cart/`

| Phương thức | Đường dẫn API | Chức năng | Ghi chú |
| :--- | :--- | :--- | :--- |
| **POST** | `/api/v2/cart/add-items` | Thêm vật tư PR vào Giỏ hàng | Gom các vật tư từ các PR đã duyệt |
| **GET** | `/api/v2/cart/<id>` | Chi tiết giỏ hàng | Xem các mặt hàng trong giỏ trước khi chuyển đổi |
| **POST** | `/api/v2/cart/<cart_id>/convert` | Chuyển đổi Giỏ hàng thành PO | Tạo Đơn mua hàng (PO) chính thức |
| **GET** | `/api/v2/cart/orders` | Danh sách Đơn mua hàng (PO) | Theo dõi tiến độ của các PO |
| **GET** | `/api/v2/cart/orders/<id>` | Chi tiết Đơn mua hàng (PO) | Xem chi tiết mặt hàng, số lượng và giá của PO |
| **POST** | `/api/v2/cart/orders/<id>/suppliers` | Thêm nhà cung cấp vào PO | Liên kết các đối tác sẽ tham gia gửi báo giá |

---

## 5. Nhóm API Đấu thầu & Báo giá (Quotation)
* **Màn hình Frontend tương ứng:** [QuotationView.vue](file:///Users/quangsangle.hn/Desktop/erp_procurement/frontend/src/views/QuotationView.vue)
* **Tiền tố đường dẫn:** `/api/v2/quotation/` và `/api/v2/vendor-portal/`

| Phương thức | Đường dẫn API | Chức năng | Ghi chú |
| :--- | :--- | :--- | :--- |
| **POST** | `/api/v2/quotation/invite` | Gửi thư mời báo giá | Mời nhà cung cấp tham gia chào giá cho PO |
| **GET** | `/api/v2/quotation/compare/<order_id>`| So sánh báo giá cạnh tranh | Bảng so sánh chéo giá cả của các nhà thầu |
| **POST** | `/api/v2/quotation/select` | Chọn nhà cung cấp chiến thắng | Chọn báo giá tốt nhất để ký hợp đồng IPO |
| **GET** | `/api/v2/quotation/<id>/versions` | Xem lịch sử cập nhật báo giá | Theo dõi các lần thay đổi giá của nhà cung cấp |
| **POST** | `/api/v2/vendor-portal/submit-bid` | Nhà cung cấp nộp báo giá | API Công khai (Public) dành cho cổng thông tin đối tác |

---

## 6. Nhóm API Hợp đồng Mua sắm (Internal Purchase Order - IPO)
* **Màn hình Frontend tương ứng:** [IpoView.vue](file:///Users/quangsangle.hn/Desktop/erp_procurement/frontend/src/views/IpoView.vue)
* **Tiền tố đường dẫn (Prefix):** `/api/v2/ipo/`

| Phương thức | Đường dẫn API | Chức năng | Ghi chú |
| :--- | :--- | :--- | :--- |
| **POST** | `/api/v2/ipo/create-version` | Tạo phiên bản hợp đồng mới | Tạo hoặc sửa đổi dự thảo hợp đồng IPO |
| **GET** | `/api/v2/ipo/` | Danh sách hợp đồng IPO | Theo dõi danh sách và trạng thái hợp đồng |
| **GET** | `/api/v2/ipo/<id>` | Chi tiết hợp đồng IPO | Các điều khoản, giá trị hợp đồng và tiến độ |
| **POST** | `/api/v2/ipo/<id>/submit` | Gửi duyệt hợp đồng | Nộp hợp đồng lên cấp trên ký duyệt |
| **GET** | `/api/v2/ipo/pending-list` | Danh sách hợp đồng chờ duyệt | Dành cho cấp phê duyệt hợp đồng |
| **POST** | `/api/v2/ipo/approve` | Phê duyệt hợp đồng IPO | Chuyển trạng thái hợp đồng thành chính thức |

---

## 7. Nhóm API Kho & Nhập kho (Warehouse & GRN)
* **Màn hình Frontend tương ứng:** [WarehouseView.vue](file:///Users/quangsangle.hn/Desktop/erp_procurement/frontend/src/views/WarehouseView.vue)
* **Tiền tố đường dẫn (Prefix):** `/api/v2/warehouse/`

| Phương thức | Đường dẫn API | Chức năng | Ghi chú |
| :--- | :--- | :--- | :--- |
| **POST** | `/api/v2/warehouse/receipt` | Lập Phiếu nhập kho (GRN) | Nhận hàng thực tế từ nhà cung cấp theo hợp đồng |
| **GET** | `/api/v2/warehouse/receipt/<id>` | Chi tiết phiếu nhập kho | Xem số lượng hàng thực nhận, hàng lỗi/hỏng |
| **GET** | `/api/v2/warehouse/inventory` | Xem tồn kho thực tế | Danh sách vật tư hiện có trong kho, hàng tạm giữ |
| **GET** | `/api/v2/warehouse/returns` | Danh sách trả hàng | Quản lý các lô hàng bị từ chối trả về nhà cung ứng |

---

## 8. Nhóm API Kế toán & Thanh toán (Invoice & Payment)
* **Màn hình Frontend tương ứng:** [FinanceView.vue](file:///Users/quangsangle.hn/Desktop/erp_procurement/frontend/src/views/FinanceView.vue)
* **Tiền tố đường dẫn (Prefix):** `/api/v2/invoice/`

| Phương thức | Đường dẫn API | Chức năng | Ghi chú |
| :--- | :--- | :--- | :--- |
| **POST** | `/api/v2/invoice/create` | Tạo hóa đơn nhà cung ứng | Đăng ký hóa đơn tài chính nhận được |
| **GET** | `/api/v2/invoice/` | Danh sách hóa đơn | Quản lý hóa đơn cần xử lý thanh toán |
| **GET** | `/api/v2/invoice/<id>` | Chi tiết hóa đơn | Thông tin chi tiết thuế, tổng tiền hóa đơn |
| **POST** | `/api/v2/invoice/verify-matching` | **Đối chiếu 3 bên (3-Way Match)** | Tự động so khớp số lượng/giá giữa PO - GRN - Invoice |
| **POST** | `/api/v2/invoice/<id>/override` | Bỏ qua sai số đối chiếu (Override)| Cho phép Kế toán trưởng duyệt các chênh lệch nhỏ |
| **POST** | `/api/v2/invoice/payment/request` | Lập yêu cầu thanh toán | Gửi đề nghị chi tiền cho hóa đơn hợp lệ |
| **GET** | `/api/v2/invoice/payment/` | Danh sách yêu cầu thanh toán | Theo dõi danh sách phiếu chi |
| **POST** | `/api/v2/invoice/payment/approve` | Phê duyệt yêu cầu thanh toán | Giám đốc Tài chính / Kế toán trưởng phê duyệt chi tiền |
