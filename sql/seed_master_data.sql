-- ============================================================
--  HỆ THỐNG QUẢN LÝ MUA HÀNG DOANH NGHIỆP SẢN XUẤT
--  SEED SCRIPT: MASTER DATA — Phiên bản 2.1
--  Ngày tạo  : 26/05/2026
-- ============================================================
--  MỤC ĐÍCH: Khởi tạo toàn bộ dữ liệu nền (Master Data) cho
--  hệ thống khi triển khai lần đầu hoặc reset môi trường DEV/UAT.
--
--  THỨ TỰ CHẠY (phụ thuộc FK):
--    1. Branches
--    2. Departments
--    3. Roles  →  Permissions  →  RolePermissions
--    4. Users
--    5. MaterialCategories  →  Materials
--    6. Suppliers  →  SupplierContractPrices
--    7. ApprovalWorkflows  →  ApprovalWorkflowSteps
--    8. SystemConfigs
--
--  LƯU Ý AN TOÀN:
--    - Script dùng MERGE nên chạy lại nhiều lần KHÔNG bị lỗi
--      duplicate (idempotent).
--    - Password mẫu là BCrypt hash của chuỗi "Abc@12345".
--      Bắt buộc đổi trước khi deploy Production.
-- ============================================================

USE ProcurementDB;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- 1. BRANCHES (Chi nhánh / Nhà máy)
-- ============================================================
PRINT '>> [1/8] Seeding Branches...';

MERGE dbo.Branches AS tgt
USING (VALUES
    ('CN-HN',  N'Chi nhánh Hà Nội',          N'Số 1 Đại Cồ Việt, Hai Bà Trưng, Hà Nội'),
    ('CN-HCM', N'Chi nhánh TP. Hồ Chí Minh', N'18 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh'),
    ('CN-DN',  N'Chi nhánh Đà Nẵng',         N'88 Điện Biên Phủ, Thanh Khê, Đà Nẵng'),
    ('CN-BPC', N'Nhà máy Bình Phước',         N'KCN Minh Hưng III, Chơn Thành, Bình Phước'),
    ('CN-HPH', N'Nhà máy Hải Phòng',          N'KCN Đình Vũ, Hải An, Hải Phòng')
) AS src (branch_code, branch_name, address)
ON tgt.branch_code = src.branch_code
WHEN NOT MATCHED THEN
    INSERT (branch_code, branch_name, address, is_active)
    VALUES (src.branch_code, src.branch_name, src.address, 1);

PRINT '   Branches: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' dòng đã thêm.';
GO

-- ============================================================
-- 2. DEPARTMENTS (Phòng ban / Bộ phận)
-- ============================================================
PRINT '>> [2/8] Seeding Departments...';

-- 2a. Phòng ban cấp 1 (parent_dept_id = NULL) — áp dụng toàn công ty
MERGE dbo.Departments AS tgt
USING (VALUES
    -- Mã phòng,   Tên phòng,                              Mã chi nhánh (NULL = chung)
    ('BAN-GD',    N'Ban Giám đốc',                         NULL),
    ('PUR',       N'Phòng Mua Hàng',                       NULL),
    ('ACC',       N'Phòng Kế Toán – Tài Chính',            NULL),
    ('PROD',      N'Phòng Sản Xuất',                       NULL),
    ('WH',        N'Phòng Kho Vận',                        NULL),
    ('QC',        N'Phòng Kiểm Định Chất Lượng (QC)',      NULL),
    ('IT',        N'Phòng Công Nghệ Thông Tin',            NULL),
    ('HR',        N'Phòng Nhân Sự – Hành Chính',           NULL),
    ('SALES',     N'Phòng Kinh Doanh',                     NULL),
    ('TECH',      N'Phòng Kỹ Thuật – Bảo Trì',            NULL)
) AS src (dept_code, dept_name, branch_code)
ON tgt.dept_code = src.dept_code
WHEN NOT MATCHED THEN
    INSERT (dept_code, dept_name, branch_id, parent_dept_id, is_active)
    VALUES (
        src.dept_code,
        src.dept_name,
        (SELECT branch_id FROM dbo.Branches WHERE branch_code = src.branch_code),
        NULL,
        1
    );

-- 2b. Phòng ban cấp 2 — con của Phòng Mua Hàng
MERGE dbo.Departments AS tgt
USING (VALUES
    ('PUR-DOM',  N'Tổ Mua Hàng Nội Địa',          'PUR'),
    ('PUR-IMP',  N'Tổ Nhập Khẩu',                 'PUR'),
    ('PUR-ADM',  N'Tổ Hành Chính Mua Hàng',       'PUR')
) AS src (dept_code, dept_name, parent_code)
ON tgt.dept_code = src.dept_code
WHEN NOT MATCHED THEN
    INSERT (dept_code, dept_name, branch_id, parent_dept_id, is_active)
    VALUES (
        src.dept_code,
        src.dept_name,
        NULL,
        (SELECT dept_id FROM dbo.Departments WHERE dept_code = src.parent_code),
        1
    );

-- 2c. Phòng ban cấp 2 — con của Phòng Kho Vận
MERGE dbo.Departments AS tgt
USING (VALUES
    ('WH-IN',    N'Tổ Nhập Kho',                  'WH'),
    ('WH-OUT',   N'Tổ Xuất Kho',                  'WH'),
    ('WH-INV',   N'Tổ Kiểm Kê Tồn Kho',           'WH')
) AS src (dept_code, dept_name, parent_code)
ON tgt.dept_code = src.dept_code
WHEN NOT MATCHED THEN
    INSERT (dept_code, dept_name, branch_id, parent_dept_id, is_active)
    VALUES (
        src.dept_code,
        src.dept_name,
        NULL,
        (SELECT dept_id FROM dbo.Departments WHERE dept_code = src.parent_code),
        1
    );

PRINT '   Departments seeding done.';
GO

-- ============================================================
-- 3. ROLES (Vai trò)
-- ============================================================
PRINT '>> [3/8] Seeding Roles, Permissions, RolePermissions...';

MERGE dbo.Roles AS tgt
USING (VALUES
    ('ADMIN',          N'Quản trị hệ thống',          N'Toàn quyền cấu hình hệ thống, người dùng, phân quyền'),
    ('GD',             N'Giám đốc / Tổng giám đốc',   N'Phê duyệt cấp cao nhất, bypass matching override'),
    ('PGD',            N'Phó giám đốc',               N'Phê duyệt cấp 2 thay thế Giám đốc'),
    ('DEPT_HEAD',      N'Trưởng phòng',               N'Duyệt PR cấp phòng ban, đánh giá NCC'),
    ('BUYER',          N'Nhân viên Mua hàng (Buyer)',  N'Tạo Order, gom giỏ, gửi báo giá, lập IPO'),
    ('ACCOUNTANT',     N'Kế toán',                    N'Nhập hóa đơn, lập phiếu thanh toán, Credit/Debit Note'),
    ('WAREHOUSE_KEEP', N'Thủ kho',                    N'Nhập kho, xuất kho, phiếu trả hàng'),
    ('QC_STAFF',       N'Nhân viên QC',               N'Kiểm định hàng nhập, ghi nhận qty_passed/qty_failed'),
    ('REQUESTER',      N'Nhân viên yêu cầu mua hàng', N'Tạo đơn PR, theo dõi trạng thái PR của mình'),
    ('VIEWER',         N'Xem báo cáo',                N'Chỉ đọc dữ liệu, không tạo hay duyệt chứng từ')
) AS src (role_code, role_name, description)
ON tgt.role_code = src.role_code
WHEN NOT MATCHED THEN
    INSERT (role_code, role_name, description, is_active)
    VALUES (src.role_code, src.role_name, src.description, 1);
GO

-- ============================================================
-- 3b. PERMISSIONS (Danh mục quyền hạn)
-- ============================================================
MERGE dbo.Permissions AS tgt
USING (VALUES
    -- AUTH
    ('USER_CREATE',         N'Tạo tài khoản người dùng',               'AUTH'),
    ('USER_EDIT',           N'Chỉnh sửa tài khoản',                    'AUTH'),
    ('USER_LOCK',           N'Khóa / mở khóa tài khoản',              'AUTH'),
    ('ROLE_ASSIGN',         N'Phân quyền vai trò',                     'AUTH'),
    -- PR
    ('PR_CREATE',           N'Tạo đơn yêu cầu mua hàng (PR)',          'PR'),
    ('PR_EDIT',             N'Chỉnh sửa PR ở trạng thái DRAFT',        'PR'),
    ('PR_SUBMIT',           N'Nộp PR để phê duyệt',                    'PR'),
    ('PR_APPROVE',          N'Phê duyệt PR',                           'PR'),
    ('PR_REJECT',           N'Từ chối PR',                             'PR'),
    ('PR_CANCEL',           N'Hủy PR',                                 'PR'),
    ('PR_VIEW_ALL',         N'Xem tất cả PR toàn hệ thống',            'PR'),
    -- CART & ORDER
    ('CART_CREATE',         N'Tạo giỏ gom hàng',                       'ORDER'),
    ('ORDER_CREATE',        N'Tạo phiên đơn hàng (Order)',             'ORDER'),
    ('ORDER_SEND_QUOTE',    N'Gửi yêu cầu báo giá NCC',               'ORDER'),
    -- IPO
    ('IPO_CREATE',          N'Tạo đơn đặt hàng nội bộ (IPO)',          'IPO'),
    ('IPO_EDIT',            N'Chỉnh sửa IPO ở trạng thái DRAFT',       'IPO'),
    ('IPO_APPROVE',         N'Phê duyệt IPO',                          'IPO'),
    ('IPO_REJECT',          N'Từ chối IPO',                            'IPO'),
    ('IPO_VIEW_ALL',        N'Xem tất cả IPO',                         'IPO'),
    -- KHO
    ('WH_RECEIPT_CREATE',   N'Tạo phiếu nhập kho',                     'KHO'),
    ('WH_ISSUE_CREATE',     N'Tạo phiếu xuất kho',                     'KHO'),
    ('WH_RETURN_CREATE',    N'Tạo phiếu trả hàng NCC',                 'KHO'),
    ('WH_INVENTORY_VIEW',   N'Xem tồn kho',                            'KHO'),
    ('WH_INVENTORY_ADJUST', N'Điều chỉnh tồn kho (admin kho)',        'KHO'),
    -- INVOICE
    ('INV_CREATE',          N'Nhập hóa đơn vào hệ thống',             'INVOICE'),
    ('INV_MATCH_RUN',       N'Chạy đối soát 3 chiều',                  'INVOICE'),
    ('INV_OVERRIDE',        N'Phê duyệt bypass đối soát sai lệch',    'INVOICE'),
    ('INV_CREDIT_NOTE',     N'Tạo Credit Note',                        'INVOICE'),
    ('INV_DEBIT_NOTE',      N'Tạo Debit Note',                         'INVOICE'),
    ('PAYMENT_CREATE',      N'Tạo phiếu đề nghị thanh toán',          'INVOICE'),
    ('PAYMENT_APPROVE',     N'Duyệt phiếu thanh toán',                'INVOICE'),
    -- NCC
    ('SUPPLIER_CREATE',     N'Thêm nhà cung cấp mới',                  'SUPPLIER'),
    ('SUPPLIER_EDIT',       N'Chỉnh sửa thông tin NCC',               'SUPPLIER'),
    ('SUPPLIER_DEACTIVATE', N'Tạm dừng hoạt động NCC',               'SUPPLIER'),
    ('SUPPLIER_EVALUATE',   N'Tạo / chốt đánh giá NCC định kỳ',       'SUPPLIER'),
    -- CATALOG
    ('MATERIAL_CREATE',     N'Thêm vật tư mới vào danh mục',          'CATALOG'),
    ('MATERIAL_EDIT',       N'Chỉnh sửa vật tư',                      'CATALOG'),
    ('MATERIAL_DEACTIVATE', N'Tạm dừng vật tư',                      'CATALOG'),
    -- CONFIG
    ('CONFIG_VIEW',         N'Xem tham số cấu hình hệ thống',          'CONFIG'),
    ('CONFIG_EDIT',         N'Chỉnh sửa tham số hệ thống',            'CONFIG'),
    ('TEMPLATE_EDIT',       N'Chỉnh sửa Email Template',              'CONFIG'),
    -- REPORT
    ('REPORT_VIEW',         N'Xem báo cáo tổng hợp',                  'REPORT'),
    ('REPORT_EXPORT',       N'Xuất dữ liệu báo cáo ra file',          'REPORT'),
    ('AUDIT_VIEW',          N'Xem nhật ký kiểm toán AuditLog',        'REPORT')
) AS src (permission_code, permission_name, module_group)
ON tgt.permission_code = src.permission_code
WHEN NOT MATCHED THEN
    INSERT (permission_code, permission_name, module_group)
    VALUES (src.permission_code, src.permission_name, src.module_group);

GO

-- ============================================================
-- 3c. ROLE PERMISSIONS (Gán quyền cho từng vai trò)
-- ============================================================
-- Helper: insert if not exists bằng MERGE
-- ADMIN — toàn quyền
INSERT INTO dbo.RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dbo.Roles r
CROSS JOIN dbo.Permissions p
WHERE r.role_code = 'ADMIN'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp
      WHERE rp.role_id = r.role_id AND rp.permission_id = p.permission_id
  );
GO

-- GD — Giám đốc: phê duyệt cao nhất + bypass + báo cáo
INSERT INTO dbo.RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dbo.Roles r
JOIN dbo.Permissions p ON p.permission_code IN (
    'PR_APPROVE','PR_REJECT','PR_VIEW_ALL',
    'IPO_APPROVE','IPO_REJECT','IPO_VIEW_ALL',
    'INV_OVERRIDE','PAYMENT_APPROVE',
    'SUPPLIER_EVALUATE','SUPPLIER_DEACTIVATE',
    'REPORT_VIEW','REPORT_EXPORT','AUDIT_VIEW',
    'CONFIG_VIEW'
)
WHERE r.role_code = 'GD'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp
      WHERE rp.role_id = r.role_id AND rp.permission_id = p.permission_id
  );
GO

-- PGD — Phó Giám đốc: tương tự GD, bỏ CONFIG_VIEW + AUDIT_VIEW
INSERT INTO dbo.RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dbo.Roles r
JOIN dbo.Permissions p ON p.permission_code IN (
    'PR_APPROVE','PR_REJECT','PR_VIEW_ALL',
    'IPO_APPROVE','IPO_REJECT','IPO_VIEW_ALL',
    'INV_OVERRIDE','PAYMENT_APPROVE',
    'SUPPLIER_EVALUATE',
    'REPORT_VIEW','REPORT_EXPORT'
)
WHERE r.role_code = 'PGD'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp
      WHERE rp.role_id = r.role_id AND rp.permission_id = p.permission_id
  );
GO

-- DEPT_HEAD — Trưởng phòng
INSERT INTO dbo.RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dbo.Roles r
JOIN dbo.Permissions p ON p.permission_code IN (
    'PR_CREATE','PR_EDIT','PR_SUBMIT','PR_APPROVE','PR_REJECT','PR_CANCEL','PR_VIEW_ALL',
    'IPO_VIEW_ALL',
    'SUPPLIER_EVALUATE',
    'WH_INVENTORY_VIEW',
    'REPORT_VIEW','REPORT_EXPORT'
)
WHERE r.role_code = 'DEPT_HEAD'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp
      WHERE rp.role_id = r.role_id AND rp.permission_id = p.permission_id
  );
GO

-- BUYER — Nhân viên mua hàng
INSERT INTO dbo.RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dbo.Roles r
JOIN dbo.Permissions p ON p.permission_code IN (
    'PR_VIEW_ALL',
    'CART_CREATE','ORDER_CREATE','ORDER_SEND_QUOTE',
    'IPO_CREATE','IPO_EDIT','IPO_VIEW_ALL',
    'SUPPLIER_CREATE','SUPPLIER_EDIT',
    'MATERIAL_CREATE','MATERIAL_EDIT',
    'WH_INVENTORY_VIEW',
    'REPORT_VIEW'
)
WHERE r.role_code = 'BUYER'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp
      WHERE rp.role_id = r.role_id AND rp.permission_id = p.permission_id
  );
GO

-- ACCOUNTANT — Kế toán
INSERT INTO dbo.RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dbo.Roles r
JOIN dbo.Permissions p ON p.permission_code IN (
    'INV_CREATE','INV_MATCH_RUN',
    'INV_CREDIT_NOTE','INV_DEBIT_NOTE',
    'PAYMENT_CREATE',
    'REPORT_VIEW','REPORT_EXPORT',
    'WH_INVENTORY_VIEW'
)
WHERE r.role_code = 'ACCOUNTANT'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp
      WHERE rp.role_id = r.role_id AND rp.permission_id = p.permission_id
  );
GO

-- WAREHOUSE_KEEP — Thủ kho
INSERT INTO dbo.RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dbo.Roles r
JOIN dbo.Permissions p ON p.permission_code IN (
    'WH_RECEIPT_CREATE','WH_ISSUE_CREATE','WH_RETURN_CREATE',
    'WH_INVENTORY_VIEW',
    'REPORT_VIEW'
)
WHERE r.role_code = 'WAREHOUSE_KEEP'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp
      WHERE rp.role_id = r.role_id AND rp.permission_id = p.permission_id
  );
GO

-- QC_STAFF — Nhân viên QC
INSERT INTO dbo.RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dbo.Roles r
JOIN dbo.Permissions p ON p.permission_code IN (
    'WH_RECEIPT_CREATE',
    'WH_INVENTORY_VIEW',
    'REPORT_VIEW'
)
WHERE r.role_code = 'QC_STAFF'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp
      WHERE rp.role_id = r.role_id AND rp.permission_id = p.permission_id
  );
GO

-- REQUESTER — Nhân viên yêu cầu
INSERT INTO dbo.RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dbo.Roles r
JOIN dbo.Permissions p ON p.permission_code IN (
    'PR_CREATE','PR_EDIT','PR_SUBMIT','PR_CANCEL'
)
WHERE r.role_code = 'REQUESTER'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp
      WHERE rp.role_id = r.role_id AND rp.permission_id = p.permission_id
  );
GO

-- VIEWER — Xem báo cáo
INSERT INTO dbo.RolePermissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM dbo.Roles r
JOIN dbo.Permissions p ON p.permission_code IN (
    'REPORT_VIEW','WH_INVENTORY_VIEW','PR_VIEW_ALL','IPO_VIEW_ALL'
)
WHERE r.role_code = 'VIEWER'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp
      WHERE rp.role_id = r.role_id AND rp.permission_id = p.permission_id
  );
GO

PRINT '   Roles / Permissions / RolePermissions seeding done.';
GO

-- ============================================================
-- 4. USERS (Tài khoản nhân viên mẫu)
-- ============================================================
-- LƯU Ý: password_hash dưới đây là BCrypt hash của "Abc@12345"
-- ($2b$12$...). Thay thế bằng hash thực trước khi deploy Production.
PRINT '>> [4/8] Seeding Users...';


-- ----------------------------
-- Records of Users
-- ----------------------------
BEGIN TRANSACTION
GO

SET IDENTITY_INSERT [dbo].[Users] ON
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'1', N'admin', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Quản Trị Hệ Thống', N'admin@company.vn', N'0901000001', N'1', N'7', N'1', N'1', N'1', N'1', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'2', N'giamdoc', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Nguyễn Văn Thắng', N'gd@company.vn', N'0901000002', N'1', N'1', N'2', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'3', N'pgd_hcm', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Trần Thị Mai', N'pgd.hcm@company.vn', N'0901000003', N'2', N'1', N'3', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'4', N'tp_muahang', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Lê Minh Tuấn', N'tp.mh@company.vn', N'0901000004', N'1', N'2', N'4', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'5', N'tp_ketoan', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Phạm Thị Hồng', N'tp.kt@company.vn', N'0901000005', N'1', N'3', N'4', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'6', N'tp_kho', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Đỗ Quang Huy', N'tp.kho@company.vn', N'0901000006', N'1', N'5', N'4', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'7', N'tp_sx', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Vũ Thị Lan', N'tp.sx@company.vn', N'0901000007', N'1', N'4', N'4', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'8', N'buyer01', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Nguyễn Thị Bích Ngọc', N'buyer01@company.vn', N'0901000008', N'1', N'11', N'5', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'9', N'buyer02', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Hoàng Văn Đức', N'buyer02@company.vn', N'0901000009', N'1', N'11', N'5', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'10', N'buyer_imp01', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Trương Quỳnh Anh', N'buyer.imp01@company.vn', N'0901000010', N'1', N'12', N'5', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'11', N'buyer_hcm01', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Phan Thanh Tùng', N'buyer.hcm01@company.vn', N'0901000011', N'2', N'2', N'5', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'12', N'accountant01', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Lương Thị Thu Hà', N'acc01@company.vn', N'0901000012', N'1', N'3', N'6', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'13', N'accountant02', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Bùi Ngọc Sơn', N'acc02@company.vn', N'0901000013', N'1', N'3', N'6', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'14', N'thuho01', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Ngô Thị Kim Phượng', N'wh01@company.vn', N'0901000014', N'1', N'14', N'7', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'15', N'thuho02', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Trần Đức Mạnh', N'wh02@company.vn', N'0901000015', N'1', N'15', N'7', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'16', N'qc01', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Đinh Văn Long', N'qc01@company.vn', N'0901000016', N'1', N'6', N'8', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'17', N'qc02', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Hà Thị Yến', N'qc02@company.vn', N'0901000017', N'4', N'6', N'8', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'18', N'nvsx01', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Mai Văn Quân', N'prod01@company.vn', N'0901000018', N'1', N'4', N'9', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'19', N'nvsx02', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Lý Thị Thu', N'prod02@company.vn', N'0901000019', N'4', N'4', N'9', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'20', N'nvtech01', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Dương Minh Khoa', N'tech01@company.vn', N'0901000020', N'1', N'10', N'9', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

INSERT INTO [dbo].[Users] ([user_id], [username], [password], [full_name], [email], [phone], [branch_id], [dept_id], [role_id], [is_active], [is_superuser], [is_staff], [last_login], [login_fail_count], [locked_until], [created_at]) VALUES (N'21', N'viewer01', N'bcrypt_sha256$$2b$12$LVljAqrzR9X1ZYzKq/SoaOoDBimB6zlofAUCYpiux3.BHXd09EhR.', N'Nguyễn Hữu Nghĩa', N'viewer01@company.vn', N'0901000021', N'1', N'7', N'10', N'1', N'0', N'0', NULL, N'0', NULL, N'2026-06-02 08:49:06.4100000')
GO

SET IDENTITY_INSERT [dbo].[Users] OFF
GO

COMMIT
GO

-- ============================================================
-- 5. MATERIAL CATEGORIES & MATERIALS (Danh mục vật tư)
-- ============================================================
PRINT '>> [5/8] Seeding MaterialCategories & Materials...';

MERGE dbo.MaterialCategories AS tgt
USING (VALUES
    ('NVL',      N'Nguyên Vật Liệu'),
    ('CCDC',     N'Công Cụ Dụng Cụ'),
    ('THIETBI',  N'Thiết Bị Máy Móc'),
    ('PHUTUNG',  N'Phụ Tùng Thay Thế'),
    ('VANPHONG', N'Văn Phòng Phẩm'),
    ('BAOHO',    N'Bảo Hộ Lao Động'),
    ('HOACHT',   N'Hóa Chất – Vật Tư Phụ Trợ'),
    ('DIEN',     N'Vật Tư Điện – Điện Tử'),
    ('XAYDUNG',  N'Vật Tư Xây Dựng'),
    ('KHAC',     N'Vật Tư Khác')
) AS src (category_code, category_name)
ON tgt.category_code = src.category_code
WHEN NOT MATCHED THEN
    INSERT (category_code, category_name, is_active)
    VALUES (src.category_code, src.category_name, 1);
GO

MERGE dbo.Materials AS tgt
USING (VALUES
    -- NVL — Nguyên Vật Liệu
    ('NVL-001', N'Thép tấm CT3 dày 3mm',                'NVL',      'kg',    500.0000,  N'Thép tấm cán nóng CT3, dày 3mm, khổ 1250x2500mm'),
    ('NVL-002', N'Thép tấm CT3 dày 5mm',                'NVL',      'kg',    300.0000,  N'Thép tấm cán nóng CT3, dày 5mm, khổ 1250x2500mm'),
    ('NVL-003', N'Thép hộp 50x50x2mm',                  'NVL',      'kg',    200.0000,  N'Thép hộp vuông Hòa Phát, 50x50x2mm, dài 6m/cây'),
    ('NVL-004', N'Thép ống phi 114 dày 4mm',             'NVL',      'kg',    150.0000,  N'Thép ống đúc phi 114mm dày 4mm, tiêu chuẩn ASTM A106'),
    ('NVL-005', N'Nhôm định hình 6063 T5',               'NVL',      'kg',    100.0000,  N'Nhôm thanh định hình 6063-T5, tiết diện hộp vuông 40x40mm'),
    ('NVL-006', N'Inox tấm SUS304 dày 2mm',             'NVL',      'kg',    80.0000,   N'Inox tấm SUS304 #2B, dày 2mm, khổ 1000x2000mm'),
    ('NVL-007', N'Nhựa PP hạt nguyên sinh',              'NVL',      'kg',    500.0000,  N'Hạt nhựa Polypropylene nguyên sinh, MFI 12, dùng ép phun'),
    ('NVL-008', N'Cao su tấm EPDM dày 5mm',             'NVL',      'm2',    50.0000,   N'Tấm cao su EPDM chịu nhiệt, dày 5mm, khổ 1200mm, cuộn 10m'),
    -- CCDC — Công cụ dụng cụ
    ('CCDC-001',N'Mũi khoan thép gió HSS phi 10mm',      'CCDC',     'cái',   20.0000,   N'Mũi khoan HSS-G phi 10mm, DIN338, Bosch hoặc tương đương'),
    ('CCDC-002',N'Đá mài góc 125x6x22mm',               'CCDC',     'cái',   50.0000,   N'Đá mài loại bỏ ba via, 125x6x22mm A24R-BF, Norton/Tyrolit'),
    ('CCDC-003',N'Đĩa cắt inox 125x1x22mm',             'CCDC',     'cái',   30.0000,   N'Đĩa cắt kim loại mỏng dành cho inox, 125x1x22mm'),
    ('CCDC-004',N'Thước kẹp điện tử 0-150mm',           'CCDC',     'cái',   5.0000,    N'Thước kẹp điện tử Mitutoyo 500-196-30, 0-150mm, 0.01mm'),
    ('CCDC-005',N'Bút thử điện có đèn LED',              'CCDC',     'cái',   10.0000,   N'Bút thử điện AC 100-500V, cách điện tiêu chuẩn IEC60900'),
    -- BAOHО — Bảo hộ lao động
    ('BHO-001', N'Kính bảo hộ chống trầy Clear',        'BAOHО',    'cái',   50.0000,   N'Kính bảo hộ trong suốt ANSI Z87.1, chống trầy xước, chống tia UV'),
    ('BHO-002', N'Găng tay chống cắt cấp 5',            'BAOHО',    'đôi',   100.0000,  N'Găng tay sợi HPPE cấp 5 chống cắt, EN388:4543, size M/L/XL'),
    ('BHO-003', N'Giày bảo hộ mũi thép S3',             'BAOHО',    'đôi',   30.0000,   N'Giày bảo hộ mũi thép + chống đâm xuyên S3 SRC, EN ISO 20345'),
    ('BHO-004', N'Nón bảo hộ ABS loại E',               'BAOHО',    'cái',   50.0000,   N'Mũ bảo hộ nhựa ABS, Class E, EN 397, nhiều màu'),
    ('BHO-005', N'Khẩu trang N95 (hộp 20 cái)',         'BAOHО',    'hộp',   30.0000,   N'Khẩu trang lọc bụi mịn N95 NIOSH, 3M 8210 hoặc tương đương'),
    -- HOACHT — Hóa chất
    ('HC-001',  N'Dầu cắt gọt kim loại Water Soluble',  'HOACHT',   'lít',   50.0000,   N'Dầu cắt hòa tan gốc khoáng, tỷ lệ pha 1:20, can 20 lít'),
    ('HC-002',  N'Mỡ bôi trơn vòng bi NLGI-2',          'HOACHT',   'kg',    20.0000,   N'Mỡ bôi trơn vòng bi chịu nhiệt Shell Alvania EP2 hoặc tương đương'),
    ('HC-003',  N'Dung môi làm sạch kim loại IPA 99%',  'HOACHT',   'lít',   30.0000,   N'Isopropyl Alcohol 99%, không để lại cặn, can 5 lít'),
    -- DIEN — Vật tư điện
    ('DIEN-001',N'Cáp điện CVV 2x1.5mm²',              'DIEN',     'm',     200.0000,  N'Cáp đồng bọc PVC CVV 2x1.5mm², 0.6/1kV, CADIVI hoặc tương đương'),
    ('DIEN-002',N'Cầu dao MCB 1P 16A',                  'DIEN',     'cái',   20.0000,   N'Cầu dao tự động MCB 1 pha 16A, 6kA, Schneider Acti9 hoặc tương đương'),
    ('DIEN-003',N'Đèn LED công nghiệp 100W IP65',       'DIEN',     'cái',   10.0000,   N'Đèn Highbay LED 100W, IP65, 5700K, hiệu suất ≥130lm/W'),
    -- VANPHONG — Văn phòng phẩm
    ('VP-001',  N'Giấy in A4 70gsm (ream 500 tờ)',      'VANPHONG', 'ream',  100.0000,  N'Giấy in laser/inkjet A4 70gsm, Double A hoặc tương đương'),
    ('VP-002',  N'Mực in laser HP đen Q7553A',          'VANPHONG', 'hộp',   5.0000,    N'Hộp mực laser HP 53A Q7553A, đen, dung lượng 3000 trang'),
    ('VP-003',  N'Bút bi Thiên Long TL-023 (hộp 20)',   'VANPHONG', 'hộp',   10.0000,  N'Bút bi mực xanh Thiên Long TL-023, ngòi 0.8mm, hộp 20 cái')
) AS src (material_code, material_name, category_code, uom, min_stock_level, description)
ON tgt.material_code = src.material_code
WHEN NOT MATCHED THEN
    INSERT (material_code, material_name, category_id, uom, min_stock_level, description, is_other, is_active)
    VALUES (
        src.material_code,
        src.material_name,
        (SELECT category_id FROM dbo.MaterialCategories WHERE category_code = src.category_code),
        src.uom,
        src.min_stock_level,
        src.description,
        0,
        1
    );

-- Thêm 1 bản ghi "Other" placeholder cho hàng tự do
MERGE dbo.Materials AS tgt
USING (VALUES ('OTHER-FREE', N'[Hàng ngoài danh mục - Nhập tay]', 'KHAC', N'cái')) AS src (material_code, material_name, category_code, uom)
ON tgt.material_code = src.material_code
WHEN NOT MATCHED THEN
    INSERT (material_code, material_name, category_id, uom, min_stock_level, is_other, is_active)
    VALUES (
        src.material_code, src.material_name,
        (SELECT category_id FROM dbo.MaterialCategories WHERE category_code = src.category_code),
        src.uom, 0, 1, 0
    );

PRINT '   MaterialCategories & Materials seeding done.';
GO

-- ============================================================
-- 6. SUPPLIERS & CONTRACT PRICES (Nhà cung cấp)
-- ============================================================
PRINT '>> [6/8] Seeding Suppliers & SupplierContractPrices...';

MERGE dbo.Suppliers AS tgt
USING (VALUES
    ('NCC-001', N'Công ty TNHH Thép Hòa Phát Hà Nội',      '0100100001', N'Nguyễn Văn An',    'thep@hoaphat.vn',        '024 3868 8888', N'KCN Phố Nối B, Văn Lâm, Hưng Yên',                      4.80),
    ('NCC-002', N'Công ty CP Vật Tư Kỹ Thuật VN (VIMAC)',  '0302000001', N'Trần Thị Bình',    'sales@vimac.com.vn',     '028 3836 0000', N'12 Điện Biên Phủ, Quận 1, TP. HCM',                     4.50),
    ('NCC-003', N'Công ty TNHH Inox Kim Long',              '0101000003', N'Lê Quang Khải',    'sales@kimlong.vn',       '024 6286 1111', N'KCN Ninh Hiệp, Gia Lâm, Hà Nội',                        4.20),
    ('NCC-004', N'Công ty CP Hóa Chất Đức Giang',           '0104000001', N'Phan Thị Cúc',     'kinhdoanh@ducgiang.vn',  '024 3826 2222', N'Phường Đức Giang, Long Biên, Hà Nội',                   4.60),
    ('NCC-005', N'Công ty CP Nhựa Đà Nẵng (DANAPLAST)',    '0400000001', N'Võ Minh Đức',      'sales@danaplast.vn',     '0236 3888 555', N'KCN Hòa Khánh, Liên Chiểu, Đà Nẵng',                   4.10),
    ('NCC-006', N'Công ty TNHH Thiết Bị Bảo Hộ An Toàn',  '0305000001', N'Đinh Thị Giang',   'info@baohoan.vn',        '028 3517 3333', N'185/8 Đinh Tiên Hoàng, Bình Thạnh, TP. HCM',            4.30),
    ('NCC-007', N'Công ty CP Điện Tử Viễn Thông Nam Việt', '0109000001', N'Hoàng Văn Hùng',   'sales@namviet-elec.vn',  '024 3944 4444', N'Lô 18 KCN Thạch Thất – Quốc Oai, Hà Nội',              4.55),
    ('NCC-008', N'Công ty TNHH Văn Phòng Phẩm Tiến Đạt',  '0200000002', N'Nguyễn Thị Lan',   'order@tiendatvpp.vn',    '028 3966 5555', N'55 Lý Thường Kiệt, Quận 5, TP. HCM',                   4.00),
    ('NCC-009', N'Công ty CP Cao Su Miền Nam (CASUMINA)',   '0301000001', N'Bùi Quốc Khánh',   'b2b@casumina.com.vn',    '028 3854 6666', N'331 Lý Thường Kiệt, Quận 10, TP. HCM',                 4.70),
    ('NCC-010', N'Công ty TNHH Công Cụ Cắt Gọt Toàn Phát','0103000001', N'Trương Ngọc Minh',  'sales@toanphat-tool.vn', '024 3792 7777', N'Số 7 Ngõ 99 Trần Phú, Hà Đông, Hà Nội',               3.90)
) AS src (supplier_code, supplier_name, tax_code, contact_name, contact_email, contact_phone, address, rating_score)
ON tgt.supplier_code = src.supplier_code
WHEN NOT MATCHED THEN
    INSERT (supplier_code, supplier_name, tax_code, contact_name, contact_email, contact_phone, address, rating_score, is_active)
    VALUES (src.supplier_code, src.supplier_name, src.tax_code, src.contact_name, src.contact_email, src.contact_phone, src.address, src.rating_score, 1);
GO

-- Giá thỏa thuận khung (Contract Prices) mẫu
MERGE dbo.SupplierContractPrices AS tgt
USING (VALUES
    -- supplier_code, material_code,  đơn giá VNĐ,  hiệu lực từ,       đến
    ('NCC-001', 'NVL-001',  18500.00, '2026-01-01', '2026-12-31'),
    ('NCC-001', 'NVL-002',  18200.00, '2026-01-01', '2026-12-31'),
    ('NCC-001', 'NVL-003',  19000.00, '2026-01-01', '2026-12-31'),
    ('NCC-003', 'NVL-006',  185000.00,'2026-01-01', '2026-12-31'),
    ('NCC-004', 'HC-001',   85000.00, '2026-01-01', '2026-12-31'),
    ('NCC-004', 'HC-002',   120000.00,'2026-01-01', '2026-12-31'),
    ('NCC-006', 'BHO-001',  45000.00, '2026-01-01', '2026-12-31'),
    ('NCC-006', 'BHO-002',  85000.00, '2026-01-01', '2026-12-31'),
    ('NCC-006', 'BHO-003',  380000.00,'2026-01-01', '2026-12-31'),
    ('NCC-007', 'DIEN-001', 12500.00, '2026-01-01', '2026-12-31'),
    ('NCC-007', 'DIEN-002', 95000.00, '2026-01-01', '2026-12-31'),
    ('NCC-008', 'VP-001',   55000.00, '2026-01-01', '2026-12-31'),
    ('NCC-010', 'CCDC-001', 28000.00, '2026-01-01', '2026-12-31'),
    ('NCC-010', 'CCDC-002', 15000.00, '2026-01-01', '2026-12-31')
) AS src (supplier_code, material_code, contract_unit_price, valid_from, valid_to)
ON tgt.supplier_id = (SELECT supplier_id FROM dbo.Suppliers WHERE supplier_code = src.supplier_code)
   AND tgt.material_id = (SELECT material_id FROM dbo.Materials WHERE material_code = src.material_code)
   AND tgt.valid_from = CAST(src.valid_from AS DATETIME2)
WHEN NOT MATCHED THEN
    INSERT (supplier_id, material_id, contract_unit_price, valid_from, valid_to)
    VALUES (
        (SELECT supplier_id FROM dbo.Suppliers WHERE supplier_code = src.supplier_code),
        (SELECT material_id FROM dbo.Materials WHERE material_code = src.material_code),
        src.contract_unit_price,
        CAST(src.valid_from AS DATETIME2),
        CAST(src.valid_to   AS DATETIME2)
    );

PRINT '   Suppliers & ContractPrices seeding done.';
GO

-- ============================================================
-- 7. APPROVAL WORKFLOWS & STEPS (Ma trận phê duyệt động)
-- ============================================================
PRINT '>> [7/8] Seeding ApprovalWorkflows & Steps...';

MERGE dbo.ApprovalWorkflows AS tgt
USING (VALUES
    -- Tên workflow,                                          object_type,  min_amount,     max_amount,  dept_code
    -- PR Thường — theo hạn mức
    (N'PR Thường — Dưới 5 triệu (Trưởng phòng duyệt)',      'PR_NORMAL',  0.00,           4999999.99,  NULL),
    (N'PR Thường — 5 đến 50 triệu (PGĐ duyệt)',             'PR_NORMAL',  5000000.00,     49999999.99, NULL),
    (N'PR Thường — Trên 50 triệu (GĐ duyệt)',               'PR_NORMAL',  50000000.00,    NULL,        NULL),
    -- PR Khẩn — rút ngắn cấp duyệt
    (N'PR Khẩn — Dưới 20 triệu (Trưởng phòng duyệt)',       'PR_URGENT',  0.00,           19999999.99, NULL),
    (N'PR Khẩn — Trên 20 triệu (GĐ duyệt)',                 'PR_URGENT',  20000000.00,    NULL,        NULL),
    -- IPO
    (N'IPO — Dưới 100 triệu (Trưởng phòng MH duyệt)',       'IPO',        0.00,           99999999.99, NULL),
    (N'IPO — 100 đến 500 triệu (PGĐ duyệt)',               'IPO',        100000000.00,   499999999.99,NULL),
    (N'IPO — Trên 500 triệu (GĐ duyệt)',                    'IPO',        500000000.00,   NULL,        NULL)
) AS src (workflow_name, object_type, min_amount, max_amount, dept_code)
ON tgt.workflow_name = src.workflow_name
WHEN NOT MATCHED THEN
    INSERT (workflow_name, object_type, min_amount, max_amount, dept_id, is_active)
    VALUES (
        src.workflow_name, src.object_type, src.min_amount, src.max_amount,
        (SELECT dept_id FROM dbo.Departments WHERE dept_code = src.dept_code),
        1
    );
GO

-- Steps cho từng workflow
-- Helper CTE để insert steps không trùng
MERGE dbo.ApprovalWorkflowSteps AS tgt
USING (
    SELECT
        w.workflow_id,
        s.step_sequence,
        r.role_id
    FROM (VALUES
        -- workflow_name,                                           step, role_code
        (N'PR Thường — Dưới 5 triệu (Trưởng phòng duyệt)',       1, 'DEPT_HEAD'),

        (N'PR Thường — 5 đến 50 triệu (PGĐ duyệt)',              1, 'DEPT_HEAD'),
        (N'PR Thường — 5 đến 50 triệu (PGĐ duyệt)',              2, 'PGD'),

        (N'PR Thường — Trên 50 triệu (GĐ duyệt)',                1, 'DEPT_HEAD'),
        (N'PR Thường — Trên 50 triệu (GĐ duyệt)',                2, 'PGD'),
        (N'PR Thường — Trên 50 triệu (GĐ duyệt)',                3, 'GD'),

        (N'PR Khẩn — Dưới 20 triệu (Trưởng phòng duyệt)',        1, 'DEPT_HEAD'),

        (N'PR Khẩn — Trên 20 triệu (GĐ duyệt)',                  1, 'DEPT_HEAD'),
        (N'PR Khẩn — Trên 20 triệu (GĐ duyệt)',                  2, 'GD'),

        (N'IPO — Dưới 100 triệu (Trưởng phòng MH duyệt)',        1, 'DEPT_HEAD'),

        (N'IPO — 100 đến 500 triệu (PGĐ duyệt)',                 1, 'DEPT_HEAD'),
        (N'IPO — 100 đến 500 triệu (PGĐ duyệt)',                 2, 'PGD'),

        (N'IPO — Trên 500 triệu (GĐ duyệt)',                     1, 'DEPT_HEAD'),
        (N'IPO — Trên 500 triệu (GĐ duyệt)',                     2, 'PGD'),
        (N'IPO — Trên 500 triệu (GĐ duyệt)',                     3, 'GD')
    ) AS step_src (workflow_name, step_sequence, role_code)
    JOIN dbo.ApprovalWorkflows w ON w.workflow_name = step_src.workflow_name
    JOIN dbo.Roles             r ON r.role_code     = step_src.role_code
) AS src (workflow_id, step_sequence, role_id)
ON  tgt.workflow_id   = src.workflow_id
AND tgt.step_sequence = src.step_sequence
AND tgt.role_id       = src.role_id
WHEN NOT MATCHED THEN
    INSERT (workflow_id, step_sequence, role_id)
    VALUES (src.workflow_id, src.step_sequence, src.role_id);

PRINT '   ApprovalWorkflows & Steps seeding done.';
GO

-- ============================================================
-- 8. SYSTEM CONFIGS (Tham số cấu hình động)
-- ============================================================
PRINT '>> [8/8] Seeding SystemConfigs...';

MERGE dbo.SystemConfigs AS tgt
USING (VALUES
    -- config_key,                          config_value_json (JSON),                     description
    ('OVER_ORDER_TOLERANCE_PERCENT',
     N'{"value": 5, "unit": "percent"}',
     N'Biên độ cho phép vượt số lượng đặt mua so với PR gốc (%). Mặc định 5%.'),

    ('OVER_RECEIVE_TOLERANCE_PERCENT',
     N'{"value": 3, "unit": "percent"}',
     N'Biên độ cho phép nhập kho vượt số lượng IPO (%). Mặc định 3%.'),

    ('INVOICE_PRICE_TOLERANCE_PERCENT',
     N'{"value": 1, "unit": "percent"}',
     N'Ngưỡng chênh lệch đơn giá hóa đơn so với IPO trước khi hệ thống báo MISMATCHED. Mặc định 1%.'),

    ('INVOICE_QTY_TOLERANCE_PERCENT',
     N'{"value": 2, "unit": "percent"}',
     N'Ngưỡng chênh lệch số lượng hóa đơn so với số lượng kho nhận đạt (qty_passed). Mặc định 2%.'),

    ('QUOTATION_DEFAULT_DEADLINE_HOURS',
     N'{"value": 72, "unit": "hours"}',
     N'Thời gian mặc định (giờ) NCC có thể nộp báo giá kể từ lúc nhận email mời. Mặc định 72 giờ.'),

    ('QUOTATION_TOKEN_EXPIRY_HOURS',
     N'{"value": 96, "unit": "hours"}',
     N'Thời gian link Token báo giá còn hiệu lực. Mặc định 96 giờ.'),

    ('MIN_SUPPLIER_QUOTE_COUNT',
     N'{"value": 3}',
     N'Số lượng báo giá tối thiểu phải thu thập trước khi cho phép chọn NCC và tạo IPO (quy tắc 3 báo giá).'),

    ('URGENT_PR_ALERT_ROLES',
     N'["DEPT_HEAD", "BUYER", "GD"]',
     N'Danh sách role_code sẽ nhận thông báo IN_APP khi có PR URGENT được tạo.'),

    ('PR_AUTO_CANCEL_AFTER_DAYS',
     N'{"value": 90, "unit": "days"}',
     N'Số ngày không có hoạt động thì hệ thống tự động hủy PR ở trạng thái DRAFT.'),

    ('IPO_VERSION_EDIT_ALLOWED_STATUSES',
     N'["DRAFT", "REJECTED"]',
     N'Các trạng thái IPO được phép tạo phiên bản mới (chỉnh sửa).'),

    ('SUPPLIER_RATING_AVERAGE_PERIODS',
     N'{"value": 4, "unit": "periods"}',
     N'Số kỳ đánh giá gần nhất dùng để tính điểm rating_score trung bình của NCC khi finalize.'),

    ('SUPPLIER_RATING_RANK_THRESHOLDS',
     N'{"GOLD": 85, "SILVER": 70, "BRONZE": 50, "WARNING": 0}',
     N'Ngưỡng điểm xếp hạng NCC. GOLD ≥85, SILVER 70-84, BRONZE 50-69, WARNING <50.'),

    ('SUPPLIER_WARNING_AUTO_NOTIFY_STREAK',
     N'{"value": 2, "unit": "periods"}',
     N'Số kỳ liên tiếp NCC bị xếp WARNING để tự động gửi thông báo đề xuất tạm dừng NCC.'),

    ('PAYMENT_LATE_REMINDER_DAYS',
     N'{"value": 3, "unit": "days"}',
     N'Số ngày trước hạn thanh toán để hệ thống gửi nhắc nhở kế toán.'),

    ('AUDIT_LOG_RETENTION_DAYS',
     N'{"value": 1825, "unit": "days"}',
     N'Thời gian lưu trữ AuditLog (1825 ngày = 5 năm). Phục vụ yêu cầu kiểm toán thuế.'),

    ('MAX_LOGIN_FAIL_BEFORE_LOCK',
     N'{"value": 5}',
     N'Số lần đăng nhập sai liên tiếp tối đa trước khi tài khoản bị khóa tạm thời.'),

    ('ACCOUNT_LOCK_DURATION_MINUTES',
     N'{"value": 30, "unit": "minutes"}',
     N'Thời gian khóa tài khoản sau khi đăng nhập sai quá số lần cho phép.'),

    ('ALLOW_SPLIT_ORDER_ACROSS_SUPPLIERS',
     N'{"value": true}',
     N'Cho phép gom hàng từ nhiều PR thành 1 Order nhưng tách IPO cho nhiều NCC khác nhau.'),

    ('STOCK_ISSUE_REQUIRE_PR_LINK',
     N'{"value": false}',
     N'Bắt buộc phiếu xuất kho phải liên kết với PR gốc. false = cho phép xuất kho không có PR.'),

    ('SYSTEM_DEFAULT_LANGUAGE',
     N'"vi"',
     N'Ngôn ngữ mặc định của hệ thống khi render Email Template và thông báo.'),

    ('COMPANY_NAME',
     N'"Công ty CP Sản Xuất ABC Việt Nam"',
     N'Tên công ty dùng trong tiêu đề email, chữ ký và báo cáo.'),

    ('COMPANY_TAX_CODE',
     N'"0123456789"',
     N'Mã số thuế công ty dùng trên các chứng từ kế toán xuất ra.'),

    ('COMPANY_ADDRESS',
     N'"KCN Phú Nghĩa, Chương Mỹ, Hà Nội, Việt Nam"',
     N'Địa chỉ trụ sở chính dùng trên email và báo cáo.'),

    ('SMTP_FROM_EMAIL',
     N'"procurement@company.vn"',
     N'Địa chỉ email gửi đi mặc định của hệ thống (FROM address).'),

    ('SMTP_FROM_NAME',
     N'"Hệ thống Mua Hàng ABC"',
     N'Tên hiển thị email gửi đi (FROM name).')

) AS src (config_key, config_value_json, description)
ON tgt.config_key = src.config_key
WHEN NOT MATCHED THEN
    INSERT (config_key, config_value_json, description, updated_at)
    VALUES (src.config_key, src.config_value_json, src.description, GETDATE())
WHEN MATCHED THEN
    -- Cập nhật description nếu đã tồn tại (không đổi value để tránh ghi đè cấu hình Production)
    UPDATE SET tgt.description = src.description;

PRINT '   SystemConfigs seeding done.';
GO

-- ============================================================
-- XÁC NHẬN KẾT QUẢ
-- ============================================================
PRINT '';
PRINT '============================================================';
PRINT '  KẾT QUẢ SEED MASTER DATA';
PRINT '============================================================';

SELECT 'Branches'               AS [Bảng], COUNT(*) AS [Số bản ghi] FROM dbo.Branches             UNION ALL
SELECT 'Departments',                       COUNT(*)               FROM dbo.Departments            UNION ALL
SELECT 'Roles',                             COUNT(*)               FROM dbo.Roles                  UNION ALL
SELECT 'Permissions',                       COUNT(*)               FROM dbo.Permissions            UNION ALL
SELECT 'RolePermissions',                   COUNT(*)               FROM dbo.RolePermissions        UNION ALL
SELECT 'Users',                             COUNT(*)               FROM dbo.Users                  UNION ALL
SELECT 'MaterialCategories',               COUNT(*)               FROM dbo.MaterialCategories     UNION ALL
SELECT 'Materials',                         COUNT(*)               FROM dbo.Materials              UNION ALL
SELECT 'Suppliers',                         COUNT(*)               FROM dbo.Suppliers              UNION ALL
SELECT 'SupplierContractPrices',           COUNT(*)               FROM dbo.SupplierContractPrices UNION ALL
SELECT 'ApprovalWorkflows',               COUNT(*)               FROM dbo.ApprovalWorkflows      UNION ALL
SELECT 'ApprovalWorkflowSteps',           COUNT(*)               FROM dbo.ApprovalWorkflowSteps  UNION ALL
SELECT 'SystemConfigs',                     COUNT(*)               FROM dbo.SystemConfigs          UNION ALL
SELECT 'EmailTemplates (từ DB script)',    COUNT(*)               FROM dbo.EmailTemplates
ORDER BY [Bảng];
GO

PRINT '';
PRINT '>> Seed Master Data hoàn tất thành công!';
PRINT '>> LƯU Ý: Đổi password_hash trong bảng Users trước khi deploy Production.';
GO
