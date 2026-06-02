-- ============================================================
--  HỆ THỐNG QUẢN LÝ MUA HÀNG DOANH NGHIỆP SẢN XUẤT
--  Database Script MSSQL — Phiên bản 2.1
--  Ngày tạo: 26/05/2026
-- ============================================================
-- HƯỚNG DẪN: Chạy script này trên SQL Server với tài khoản có
-- quyền CREATE DATABASE, CREATE TABLE, CREATE FULLTEXT CATALOG.
-- ============================================================

USE master;
GO

-- ============================================================
-- TẠO DATABASE
-- ============================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'ProcurementDB')
BEGIN
    CREATE DATABASE ProcurementDB
    COLLATE Vietnamese_CI_AS;
END
GO

USE ProcurementDB;
GO

-- ============================================================
-- MODULE 1: AUTHENTICATION & PHÂN QUYỀN (RBAC)
-- ============================================================

-- Bảng: Branches (Chi nhánh / Nhà máy)
IF OBJECT_ID('dbo.Branches', 'U') IS NULL
CREATE TABLE dbo.Branches (
    branch_id   INT           IDENTITY(1,1) PRIMARY KEY,
    branch_code NVARCHAR(20)  NOT NULL,
    branch_name NVARCHAR(200) NOT NULL,
    address     NVARCHAR(500) NULL,
    is_active   BIT           NOT NULL CONSTRAINT DF_Branches_IsActive   DEFAULT 1,
    created_at  DATETIME2     NOT NULL CONSTRAINT DF_Branches_CreatedAt  DEFAULT GETDATE(),
    updated_at  DATETIME2     NULL,
    CONSTRAINT UQ_Branches_Code UNIQUE (branch_code)
);
GO

-- Bảng: Departments (Phòng ban / Bộ phận)
IF OBJECT_ID('dbo.Departments', 'U') IS NULL
CREATE TABLE dbo.Departments (
    dept_id        INT           IDENTITY(1,1) PRIMARY KEY,
    dept_code      NVARCHAR(20)  NOT NULL,
    dept_name      NVARCHAR(200) NOT NULL,
    branch_id      INT           NULL,
    parent_dept_id INT           NULL,
    is_active      BIT           NOT NULL CONSTRAINT DF_Departments_IsActive  DEFAULT 1,
    created_at     DATETIME2     NOT NULL CONSTRAINT DF_Departments_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT UQ_Departments_Code UNIQUE (dept_code),
    CONSTRAINT FK_Departments_Branch FOREIGN KEY (branch_id)
        REFERENCES dbo.Branches (branch_id),
    CONSTRAINT FK_Departments_Parent FOREIGN KEY (parent_dept_id)
        REFERENCES dbo.Departments (dept_id)
);
GO

-- Bảng: Roles (Vai trò người dùng)
IF OBJECT_ID('dbo.Roles', 'U') IS NULL
CREATE TABLE dbo.Roles (
    role_id     INT           IDENTITY(1,1) PRIMARY KEY,
    role_code   NVARCHAR(50)  NOT NULL,
    role_name   NVARCHAR(100) NOT NULL,
    description NVARCHAR(300) NULL,
    is_active   BIT           NOT NULL CONSTRAINT DF_Roles_IsActive DEFAULT 1,
    CONSTRAINT UQ_Roles_Code UNIQUE (role_code)
);
GO

-- Bảng: Users (Tài khoản nhân viên)
IF OBJECT_ID('dbo.Users', 'U') IS NULL
CREATE TABLE dbo.Users (
    user_id          INT           IDENTITY(1,1) PRIMARY KEY,
    username         NVARCHAR(50)  NOT NULL,
    password    NVARCHAR(255) NOT NULL,
    full_name        NVARCHAR(150) NOT NULL,
    email            NVARCHAR(100) NOT NULL,
    phone            NVARCHAR(20)  NULL,
    branch_id        INT           NULL,
    dept_id          INT           NULL,
    role_id          INT           NULL,
    is_active        BIT           NOT NULL CONSTRAINT DF_Users_IsActive       DEFAULT 1,
    is_superuser     BIT           NOT NULL CONSTRAINT DF_Users_IsSuperuser   DEFAULT 0,
    is_staff         BIT           NOT NULL CONSTRAINT DF_Users_IsStaff       DEFAULT 0,
    last_login         DATETIME2     NULL,
    login_fail_count INT           NOT NULL CONSTRAINT DF_Users_LoginFail      DEFAULT 0,
    locked_until     DATETIME2     NULL,
    created_at       DATETIME2     NOT NULL CONSTRAINT DF_Users_CreatedAt      DEFAULT GETDATE(),
    CONSTRAINT UQ_Users_Username UNIQUE (username),
    CONSTRAINT UQ_Users_Email    UNIQUE (email),
    CONSTRAINT FK_Users_Branch   FOREIGN KEY (branch_id) REFERENCES dbo.Branches    (branch_id),
    CONSTRAINT FK_Users_Dept     FOREIGN KEY (dept_id)   REFERENCES dbo.Departments (dept_id),
    CONSTRAINT FK_Users_Role     FOREIGN KEY (role_id)   REFERENCES dbo.Roles       (role_id)
);
GO

-- Bảng: Permissions (Danh mục quyền hạn hệ thống)
IF OBJECT_ID('dbo.Permissions', 'U') IS NULL
CREATE TABLE dbo.Permissions (
    permission_id   INT            IDENTITY(1,1) PRIMARY KEY,
    permission_code NVARCHAR(100)  NOT NULL,
    permission_name NVARCHAR(150)  NOT NULL,
    module_group    NVARCHAR(50)   NOT NULL,
    CONSTRAINT UQ_Permissions_Code UNIQUE (permission_code)
);
GO

-- Bảng: RolePermissions (Bảng trung gian phân quyền)
IF OBJECT_ID('dbo.RolePermissions', 'U') IS NULL
CREATE TABLE dbo.RolePermissions (
    role_id       INT       NOT NULL,
    permission_id INT       NOT NULL,
    assigned_at   DATETIME2 NOT NULL CONSTRAINT DF_RolePermissions_AssignedAt DEFAULT GETDATE(),
    CONSTRAINT PK_RolePermissions PRIMARY KEY (role_id, permission_id),
    CONSTRAINT FK_RolePermissions_Role       FOREIGN KEY (role_id)       REFERENCES dbo.Roles       (role_id),
    CONSTRAINT FK_RolePermissions_Permission FOREIGN KEY (permission_id) REFERENCES dbo.Permissions (permission_id)
);
GO

-- ============================================================
-- MODULE 2: MASTER DATA (DANH MỤC GỐC)
-- ============================================================

-- Bảng: MaterialCategories (Phân loại vật tư)
IF OBJECT_ID('dbo.MaterialCategories', 'U') IS NULL
CREATE TABLE dbo.MaterialCategories (
    category_id   INT           IDENTITY(1,1) PRIMARY KEY,
    category_code NVARCHAR(20)  NOT NULL,
    category_name NVARCHAR(150) NOT NULL,
    is_active     BIT           NOT NULL CONSTRAINT DF_MaterialCategories_IsActive DEFAULT 1,
    CONSTRAINT UQ_MaterialCategories_Code UNIQUE (category_code)
);
GO

-- Bảng: Materials (Danh mục vật tư chuẩn)
-- Lưu ý: Full-Text Index trên material_name và description sẽ được tạo riêng ở cuối script
IF OBJECT_ID('dbo.Materials', 'U') IS NULL
CREATE TABLE dbo.Materials (
    material_id      INT            IDENTITY(1,1) PRIMARY KEY,
    material_code    NVARCHAR(50)   NOT NULL,
    material_name    NVARCHAR(300)  NOT NULL,
    category_id      INT            NULL,
    uom              NVARCHAR(30)   NOT NULL,
    min_stock_level  DECIMAL(18,4)  NOT NULL CONSTRAINT DF_Materials_MinStock DEFAULT 0,
    description      NVARCHAR(500)  NULL,
    is_other         BIT            NOT NULL CONSTRAINT DF_Materials_IsOther  DEFAULT 0,
    is_active        BIT            NOT NULL CONSTRAINT DF_Materials_IsActive DEFAULT 1,
    created_at       DATETIME2      NOT NULL CONSTRAINT DF_Materials_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT UQ_Materials_Code    UNIQUE (material_code),
    CONSTRAINT FK_Materials_Category FOREIGN KEY (category_id) REFERENCES dbo.MaterialCategories (category_id)
);
GO

-- Bảng: Suppliers (Danh mục Nhà cung cấp)
IF OBJECT_ID('dbo.Suppliers', 'U') IS NULL
CREATE TABLE dbo.Suppliers (
    supplier_id    INT            IDENTITY(1,1) PRIMARY KEY,
    supplier_code  NVARCHAR(30)   NOT NULL,
    supplier_name  NVARCHAR(250)  NOT NULL,
    tax_code       NVARCHAR(20)   NULL,
    contact_name   NVARCHAR(100)  NULL,
    contact_email  NVARCHAR(100)  NOT NULL,
    contact_phone  NVARCHAR(20)   NULL,
    address        NVARCHAR(500)  NULL,
    rating_score   DECIMAL(5,2)   NOT NULL CONSTRAINT DF_Suppliers_Rating  DEFAULT 5.00,
    is_active      BIT            NOT NULL CONSTRAINT DF_Suppliers_IsActive DEFAULT 1,
    created_at     DATETIME2      NOT NULL CONSTRAINT DF_Suppliers_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT UQ_Suppliers_Code UNIQUE (supplier_code)
);
GO

-- Bảng: SupplierContractPrices (Giá thỏa thuận khung / Giá hợp đồng)
IF OBJECT_ID('dbo.SupplierContractPrices', 'U') IS NULL
CREATE TABLE dbo.SupplierContractPrices (
    contract_price_id   INT           IDENTITY(1,1) PRIMARY KEY,
    supplier_id         INT           NOT NULL,
    material_id         INT           NOT NULL,
    contract_unit_price DECIMAL(18,2) NOT NULL,
    valid_from          DATETIME2     NOT NULL,
    valid_to            DATETIME2     NOT NULL,
    created_at          DATETIME2     NOT NULL CONSTRAINT DF_ContractPrices_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT FK_ContractPrices_Supplier FOREIGN KEY (supplier_id) REFERENCES dbo.Suppliers (supplier_id),
    CONSTRAINT FK_ContractPrices_Material FOREIGN KEY (material_id) REFERENCES dbo.Materials (material_id),
    CONSTRAINT CK_ContractPrices_Dates   CHECK (valid_to >= valid_from)
);
GO

-- ============================================================
-- CẤU HÌNH MA TRẬN PHÊ DUYỆT ĐỘNG (APPROVAL MATRIX)
-- ============================================================

-- Bảng: ApprovalWorkflows (Luồng quy trình phê duyệt)
IF OBJECT_ID('dbo.ApprovalWorkflows', 'U') IS NULL
CREATE TABLE dbo.ApprovalWorkflows (
    workflow_id   INT            IDENTITY(1,1) PRIMARY KEY,
    workflow_name NVARCHAR(100)  NOT NULL,
    object_type   NVARCHAR(50)   NOT NULL,
    min_amount    DECIMAL(18,2)  NOT NULL CONSTRAINT DF_ApprovalWorkflows_MinAmount DEFAULT 0,
    max_amount    DECIMAL(18,2)  NULL,
    dept_id       INT            NULL,
    is_active     BIT            NOT NULL CONSTRAINT DF_ApprovalWorkflows_IsActive DEFAULT 1,
    CONSTRAINT FK_ApprovalWorkflows_Dept    FOREIGN KEY (dept_id) REFERENCES dbo.Departments (dept_id),
    CONSTRAINT CK_ApprovalWorkflows_Amount CHECK (max_amount IS NULL OR max_amount >= min_amount)
);
GO

-- Bảng: ApprovalWorkflowSteps (Cấu hình chi tiết các cấp duyệt)
IF OBJECT_ID('dbo.ApprovalWorkflowSteps', 'U') IS NULL
CREATE TABLE dbo.ApprovalWorkflowSteps (
    step_id       INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    workflow_id   INT NOT NULL,
    step_sequence INT NOT NULL,
    role_id       INT NOT NULL,
    CONSTRAINT FK_ApprovalSteps_Workflow FOREIGN KEY (workflow_id) REFERENCES dbo.ApprovalWorkflows (workflow_id),
    CONSTRAINT FK_ApprovalSteps_Role     FOREIGN KEY (role_id)     REFERENCES dbo.Roles             (role_id)
);
GO

-- ============================================================
-- MODULE 3: PURCHASE REQUISITION (YÊU CẦU MUA HÀNG)
-- ============================================================

-- Bảng: PurchaseRequisitions (Đơn yêu cầu mua hàng PR)
IF OBJECT_ID('dbo.PurchaseRequisitions', 'U') IS NULL
CREATE TABLE dbo.PurchaseRequisitions (
    pr_id                  INT            IDENTITY(1,1) PRIMARY KEY,
    pr_code                NVARCHAR(30)   NOT NULL,
    requester_user_id      INT            NOT NULL,
    branch_id              INT            NOT NULL,
    dept_id                INT            NOT NULL,
    priority_level         NVARCHAR(20)   NOT NULL CONSTRAINT DF_PR_Priority    DEFAULT 'NORMAL',
    urgent_reason          NVARCHAR(500)  NULL,
    urgency_impact         NVARCHAR(500)  NULL,
    pr_status              NVARCHAR(30)   NOT NULL CONSTRAINT DF_PR_Status      DEFAULT 'DRAFT',
    total_estimated_amount DECIMAL(18,2)  NOT NULL CONSTRAINT DF_PR_TotalAmount DEFAULT 0,
    created_at             DATETIME2      NOT NULL CONSTRAINT DF_PR_CreatedAt   DEFAULT GETDATE(),
    updated_at             DATETIME2      NULL,
    CONSTRAINT UQ_PR_Code              UNIQUE (pr_code),
    CONSTRAINT FK_PR_Requester         FOREIGN KEY (requester_user_id) REFERENCES dbo.Users       (user_id),
    CONSTRAINT FK_PR_Branch            FOREIGN KEY (branch_id)         REFERENCES dbo.Branches    (branch_id),
    CONSTRAINT FK_PR_Dept              FOREIGN KEY (dept_id)           REFERENCES dbo.Departments (dept_id),
    CONSTRAINT CK_PR_Priority          CHECK (priority_level IN ('NORMAL', 'URGENT')),
    CONSTRAINT CK_PR_Status            CHECK (pr_status IN ('DRAFT', 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
    CONSTRAINT CK_PR_UrgentFields      CHECK (
        priority_level <> 'URGENT'
        OR (urgent_reason IS NOT NULL AND urgency_impact IS NOT NULL)
    )
);
GO

-- Bảng: PRItems (Chi tiết các mặt hàng trong đơn PR)
IF OBJECT_ID('dbo.PRItems', 'U') IS NULL
CREATE TABLE dbo.PRItems (
    pr_item_id           INT            IDENTITY(1,1) PRIMARY KEY,
    pr_id                INT            NOT NULL,
    material_id          INT            NULL,
    material_name_other  NVARCHAR(300)  NULL,
    qty_requested        DECIMAL(18,4)  NOT NULL,
    qty_ordered          DECIMAL(18,4)  NOT NULL CONSTRAINT DF_PRItems_QtyOrdered  DEFAULT 0,
    qty_received         DECIMAL(18,4)  NOT NULL CONSTRAINT DF_PRItems_QtyReceived DEFAULT 0,
    estimated_unit_price DECIMAL(18,2)  NOT NULL CONSTRAINT DF_PRItems_UnitPrice   DEFAULT 0,
    required_deadline    DATETIME2      NOT NULL,
    item_status          NVARCHAR(30)   NOT NULL CONSTRAINT DF_PRItems_Status      DEFAULT 'PENDING',
    CONSTRAINT FK_PRItems_PR       FOREIGN KEY (pr_id)        REFERENCES dbo.PurchaseRequisitions (pr_id),
    CONSTRAINT FK_PRItems_Material FOREIGN KEY (material_id)  REFERENCES dbo.Materials            (material_id),
    CONSTRAINT CK_PRItems_QtyPositive       CHECK (qty_requested > 0),
    CONSTRAINT CK_PRItems_QtyOrderedSanity  CHECK (qty_ordered  <= qty_requested),
    CONSTRAINT CK_PRItems_QtyReceivedSanity CHECK (qty_received <= qty_ordered),
    CONSTRAINT CK_PRItems_MaterialCheck     CHECK (
        (material_id IS NOT NULL AND material_name_other IS NULL)
        OR (material_id IS NULL AND material_name_other IS NOT NULL)
    )
);
GO

-- Bảng: DocumentApprovalProgress (Theo dõi tiến độ duyệt thực tế)
IF OBJECT_ID('dbo.DocumentApprovalProgress', 'U') IS NULL
CREATE TABLE dbo.DocumentApprovalProgress (
    progress_id      INT           IDENTITY(1,1) PRIMARY KEY,
    document_type    NVARCHAR(50)  NOT NULL,
    document_id      INT           NOT NULL,
    step_sequence    INT           NOT NULL,
    approver_user_id INT           NULL,
    approval_status  NVARCHAR(20)  NOT NULL CONSTRAINT DF_DocApproval_Status DEFAULT 'PENDING',
    comment          NVARCHAR(500) NULL,
    action_date      DATETIME2     NULL,
    CONSTRAINT FK_DocApproval_Approver FOREIGN KEY (approver_user_id) REFERENCES dbo.Users (user_id),
    CONSTRAINT CK_DocApproval_Status   CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED'))
);
GO

-- Bảng: PRStatusHistory (Lịch sử chuyển đổi trạng thái tổng đơn PR)
IF OBJECT_ID('dbo.PRStatusHistory', 'U') IS NULL
CREATE TABLE dbo.PRStatusHistory (
    history_id         INT           IDENTITY(1,1) PRIMARY KEY,
    pr_id              INT           NOT NULL,
    from_status        NVARCHAR(30)  NOT NULL,
    to_status          NVARCHAR(30)  NOT NULL,
    changed_by_user_id INT           NOT NULL,
    note               NVARCHAR(500) NULL,
    changed_at         DATETIME2     NOT NULL CONSTRAINT DF_PRStatusHistory_ChangedAt DEFAULT GETDATE(),
    CONSTRAINT FK_PRStatusHistory_PR   FOREIGN KEY (pr_id)              REFERENCES dbo.PurchaseRequisitions (pr_id),
    CONSTRAINT FK_PRStatusHistory_User FOREIGN KEY (changed_by_user_id) REFERENCES dbo.Users               (user_id)
);
GO

-- ============================================================
-- MODULE 4: CART & ORDER (GOM HÀNG VÀ ĐIỀU PHỐI ĐẶT HÀNG)
-- ============================================================

-- Bảng: Carts (Giỏ gom hàng)
IF OBJECT_ID('dbo.Carts', 'U') IS NULL
CREATE TABLE dbo.Carts (
    cart_id       INT            IDENTITY(1,1) PRIMARY KEY,
    cart_title    NVARCHAR(150)  NOT NULL,
    buyer_user_id INT            NOT NULL,
    created_at    DATETIME2      NOT NULL CONSTRAINT DF_Carts_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT FK_Carts_Buyer FOREIGN KEY (buyer_user_id) REFERENCES dbo.Users (user_id)
);
GO

-- Bảng: CartPRItems (Bảng trung gian liên kết dòng PR vào Giỏ hàng)
IF OBJECT_ID('dbo.CartPRItems', 'U') IS NULL
CREATE TABLE dbo.CartPRItems (
    cart_id    INT           NOT NULL,
    pr_item_id INT           NOT NULL,
    qty_in_cart DECIMAL(18,4) NOT NULL,
    added_at    DATETIME2     NOT NULL CONSTRAINT DF_CartPRItems_AddedAt DEFAULT GETDATE(),
    CONSTRAINT PK_CartPRItems    PRIMARY KEY (cart_id, pr_item_id),
    CONSTRAINT FK_CartPRItems_Cart   FOREIGN KEY (cart_id)    REFERENCES dbo.Carts   (cart_id),
    CONSTRAINT FK_CartPRItems_PRItem FOREIGN KEY (pr_item_id) REFERENCES dbo.PRItems (pr_item_id),
    CONSTRAINT CK_CartPRItems_Qty    CHECK (qty_in_cart > 0)
);
GO

-- Bảng: Orders (Phiên làm việc điều phối thu thập báo giá)
IF OBJECT_ID('dbo.Orders', 'U') IS NULL
CREATE TABLE dbo.Orders (
    order_id      INT           IDENTITY(1,1) PRIMARY KEY,
    order_code    NVARCHAR(30)  NOT NULL,
    buyer_user_id INT           NOT NULL,
    order_status  NVARCHAR(30)  NOT NULL CONSTRAINT DF_Orders_Status    DEFAULT 'DRAFT',
    created_at    DATETIME2     NOT NULL CONSTRAINT DF_Orders_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT UQ_Orders_Code   UNIQUE (order_code),
    CONSTRAINT FK_Orders_Buyer  FOREIGN KEY (buyer_user_id) REFERENCES dbo.Users (user_id),
    CONSTRAINT CK_Orders_Status CHECK (order_status IN ('DRAFT', 'QUOTING', 'COMPLETED'))
);
GO

-- Bảng: OrderItems (Chi tiết tổng khối lượng mặt hàng gom mua)
IF OBJECT_ID('dbo.OrderItems', 'U') IS NULL
CREATE TABLE dbo.OrderItems (
    order_item_id      INT            IDENTITY(1,1) PRIMARY KEY,
    order_id           INT            NOT NULL,
    material_id        INT            NULL,
    material_name_other NVARCHAR(300) NULL,
    qty_total_ordered  DECIMAL(18,4)  NOT NULL,
    CONSTRAINT FK_OrderItems_Order    FOREIGN KEY (order_id)    REFERENCES dbo.Orders    (order_id),
    CONSTRAINT FK_OrderItems_Material FOREIGN KEY (material_id) REFERENCES dbo.Materials (material_id),
    CONSTRAINT CK_OrderItems_Qty             CHECK (qty_total_ordered > 0),
    CONSTRAINT CK_OrderItems_MaterialCheck   CHECK (
        (material_id IS NOT NULL AND material_name_other IS NULL)
        OR (material_id IS NULL AND material_name_other IS NOT NULL)
    )
);
GO

-- Bảng: OrderItemPRLinks (Phân rã nguồn gốc OrderItem từ các PR)
IF OBJECT_ID('dbo.OrderItemPRLinks', 'U') IS NULL
CREATE TABLE dbo.OrderItemPRLinks (
    order_item_id INT           NOT NULL,
    pr_item_id    INT           NOT NULL,
    qty_linked    DECIMAL(18,4) NOT NULL,
    CONSTRAINT PK_OrderItemPRLinks       PRIMARY KEY (order_item_id, pr_item_id),
    CONSTRAINT FK_OrderItemPRLinks_Order FOREIGN KEY (order_item_id) REFERENCES dbo.OrderItems (order_item_id),
    CONSTRAINT FK_OrderItemPRLinks_PR    FOREIGN KEY (pr_item_id)    REFERENCES dbo.PRItems    (pr_item_id)
);
GO

-- Bảng: OrderSuppliers (Danh sách NCC được mời chào giá)
IF OBJECT_ID('dbo.OrderSuppliers', 'U') IS NULL
CREATE TABLE dbo.OrderSuppliers (
    order_id    INT       NOT NULL,
    supplier_id INT       NOT NULL,
    assigned_at DATETIME2 NOT NULL CONSTRAINT DF_OrderSuppliers_AssignedAt DEFAULT GETDATE(),
    CONSTRAINT PK_OrderSuppliers          PRIMARY KEY (order_id, supplier_id),
    CONSTRAINT FK_OrderSuppliers_Order    FOREIGN KEY (order_id)    REFERENCES dbo.Orders    (order_id),
    CONSTRAINT FK_OrderSuppliers_Supplier FOREIGN KEY (supplier_id) REFERENCES dbo.Suppliers (supplier_id)
);
GO

-- ============================================================
-- MODULE 5: QUOTATION PORTAL (CỔNG BÁO GIÁ NCC)
-- ============================================================

-- Bảng: QuotationRequests (Yêu cầu gửi báo giá)
IF OBJECT_ID('dbo.QuotationRequests', 'U') IS NULL
CREATE TABLE dbo.QuotationRequests (
    q_request_id       INT       IDENTITY(1,1) PRIMARY KEY,
    order_id           INT       NOT NULL,
    supplier_id        INT       NOT NULL,
    deadline_submission DATETIME2 NOT NULL,
    sent_at            DATETIME2  NOT NULL CONSTRAINT DF_QuotationRequests_SentAt DEFAULT GETDATE(),
    CONSTRAINT FK_QuotationRequests_Order    FOREIGN KEY (order_id)    REFERENCES dbo.Orders    (order_id),
    CONSTRAINT FK_QuotationRequests_Supplier FOREIGN KEY (supplier_id) REFERENCES dbo.Suppliers (supplier_id)
);
GO

-- Bảng: QuotationTokens (Quản lý chuỗi khóa bảo mật)
IF OBJECT_ID('dbo.QuotationTokens', 'U') IS NULL
CREATE TABLE dbo.QuotationTokens (
    token_id     INT            IDENTITY(1,1) PRIMARY KEY,
    q_request_id INT            NOT NULL,
    token        NVARCHAR(128)  NOT NULL,
    expires_at   DATETIME2      NOT NULL,
    is_used      BIT            NOT NULL CONSTRAINT DF_QTokens_IsUsed   DEFAULT 0,
    used_at      DATETIME2      NULL,
    created_at   DATETIME2      NOT NULL CONSTRAINT DF_QTokens_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT UQ_QuotationTokens_Token UNIQUE (token),
    CONSTRAINT FK_QuotationTokens_Request FOREIGN KEY (q_request_id) REFERENCES dbo.QuotationRequests (q_request_id)
);
GO

-- Bảng: Quotations (Tổng đơn nộp báo giá từ NCC)
IF OBJECT_ID('dbo.Quotations', 'U') IS NULL
CREATE TABLE dbo.Quotations (
    quotation_id          INT            IDENTITY(1,1) PRIMARY KEY,
    q_request_id          INT            NOT NULL,
    supplier_id           INT            NOT NULL,
    submitted_at          DATETIME2      NOT NULL CONSTRAINT DF_Quotations_SubmittedAt DEFAULT GETDATE(),
    delivery_lead_time_days INT          NOT NULL,
    payment_terms_note    NVARCHAR(200)  NULL,
    total_quote_amount    DECIMAL(18,2)  NOT NULL CONSTRAINT DF_Quotations_TotalAmount DEFAULT 0,
    is_selected           BIT            NOT NULL CONSTRAINT DF_Quotations_IsSelected  DEFAULT 0,
    CONSTRAINT FK_Quotations_Request  FOREIGN KEY (q_request_id) REFERENCES dbo.QuotationRequests (q_request_id),
    CONSTRAINT FK_Quotations_Supplier FOREIGN KEY (supplier_id)  REFERENCES dbo.Suppliers         (supplier_id)
);
GO

-- Bảng: QuotationItems (Chi tiết đơn giá chào thầu)
IF OBJECT_ID('dbo.QuotationItems', 'U') IS NULL
CREATE TABLE dbo.QuotationItems (
    q_item_id       INT            IDENTITY(1,1) PRIMARY KEY,
    quotation_id    INT            NOT NULL,
    order_item_id   INT            NOT NULL,
    quoted_unit_price DECIMAL(18,2) NOT NULL,
    supplier_note   NVARCHAR(300)  NULL,
    CONSTRAINT FK_QuotationItems_Quotation  FOREIGN KEY (quotation_id)  REFERENCES dbo.Quotations  (quotation_id),
    CONSTRAINT FK_QuotationItems_OrderItem  FOREIGN KEY (order_item_id) REFERENCES dbo.OrderItems  (order_item_id),
    CONSTRAINT CK_QuotationItems_Price      CHECK (quoted_unit_price >= 0)
);
GO

-- Bảng: QuotationVersions (Lịch sử các phiên bản báo giá NCC) [v2.1]
IF OBJECT_ID('dbo.QuotationVersions', 'U') IS NULL
CREATE TABLE dbo.QuotationVersions (
    version_id             INT            IDENTITY(1,1) PRIMARY KEY,
    quotation_id           INT            NOT NULL,
    version_number         INT            NOT NULL,
    is_current             BIT            NOT NULL CONSTRAINT DF_QVersions_IsCurrent DEFAULT 0,
    snapshot_total_amount  DECIMAL(18,2)  NOT NULL,
    snapshot_lead_time_days INT           NOT NULL,
    snapshot_payment_terms NVARCHAR(200)  NULL,
    snapshot_items_json    NVARCHAR(MAX)  NOT NULL,
    submitted_at           DATETIME2      NOT NULL CONSTRAINT DF_QVersions_SubmittedAt DEFAULT GETDATE(),
    submitted_ip           NVARCHAR(45)   NULL,
    change_summary         NVARCHAR(500)  NULL,
    CONSTRAINT FK_QuotationVersions_Quotation FOREIGN KEY (quotation_id) REFERENCES dbo.Quotations (quotation_id),
    CONSTRAINT UQ_QuotationVersions_Number    UNIQUE (quotation_id, version_number),
    CONSTRAINT CK_QuotationVersions_VersionPositive      CHECK (version_number > 0),
    CONSTRAINT CK_QuotationVersions_AmountNonNegative    CHECK (snapshot_total_amount >= 0)
);
GO

-- ============================================================
-- MODULE 6: INTERNAL PO (IPO ĐA PHIÊN BẢN)
-- ============================================================

-- Bảng: IPOs (Đơn đặt hàng mua nội bộ)
IF OBJECT_ID('dbo.IPOs', 'U') IS NULL
CREATE TABLE dbo.IPOs (
    ipo_id        INT            IDENTITY(1,1) PRIMARY KEY,
    ipo_code      NVARCHAR(30)   NOT NULL,
    version       INT            NOT NULL CONSTRAINT DF_IPOs_Version   DEFAULT 1,
    is_latest     BIT            NOT NULL CONSTRAINT DF_IPOs_IsLatest  DEFAULT 1,
    order_id      INT            NOT NULL,
    supplier_id   INT            NOT NULL,
    buyer_user_id INT            NOT NULL,
    total_amount  DECIMAL(18,2)  NOT NULL,
    ipo_status    NVARCHAR(30)   NOT NULL CONSTRAINT DF_IPOs_Status    DEFAULT 'DRAFT',
    signed_pdf_path NVARCHAR(500) NULL,
    created_at    DATETIME2      NOT NULL CONSTRAINT DF_IPOs_CreatedAt DEFAULT GETDATE(),
    updated_at    DATETIME2      NULL,
    CONSTRAINT FK_IPOs_Order    FOREIGN KEY (order_id)      REFERENCES dbo.Orders    (order_id),
    CONSTRAINT FK_IPOs_Supplier FOREIGN KEY (supplier_id)   REFERENCES dbo.Suppliers (supplier_id),
    CONSTRAINT FK_IPOs_Buyer    FOREIGN KEY (buyer_user_id) REFERENCES dbo.Users     (user_id),
    CONSTRAINT CK_IPOs_Status   CHECK (ipo_status IN ('DRAFT', 'PENDING', 'APPROVED', 'REJECTED'))
);
GO

-- Bảng: IPOItems (Chi tiết số lượng và đơn giá chốt mua IPO)
IF OBJECT_ID('dbo.IPOItems', 'U') IS NULL
CREATE TABLE dbo.IPOItems (
    ipo_item_id       INT            IDENTITY(1,1) PRIMARY KEY,
    ipo_id            INT            NOT NULL,
    order_item_id     INT            NOT NULL,
    qty_final         DECIMAL(18,4)  NOT NULL,
    unit_price_final  DECIMAL(18,2)  NOT NULL,
    item_total_amount DECIMAL(18,2)  NOT NULL,
    CONSTRAINT FK_IPOItems_IPO       FOREIGN KEY (ipo_id)        REFERENCES dbo.IPOs       (ipo_id),
    CONSTRAINT FK_IPOItems_OrderItem FOREIGN KEY (order_item_id) REFERENCES dbo.OrderItems (order_item_id),
    CONSTRAINT CK_IPOItems_Values    CHECK (qty_final > 0 AND unit_price_final >= 0)
);
GO

-- ============================================================
-- MODULE 7: WAREHOUSE MANAGEMENT (KHO VẬN)
-- ============================================================

-- Bảng: StockReceipts (Đơn nhập kho)
IF OBJECT_ID('dbo.StockReceipts', 'U') IS NULL
CREATE TABLE dbo.StockReceipts (
    receipt_id         INT            IDENTITY(1,1) PRIMARY KEY,
    receipt_code       NVARCHAR(30)   NOT NULL,
    ipo_id             INT            NOT NULL,
    warehouse_keeper_id INT           NOT NULL,
    received_at        DATETIME2      NOT NULL CONSTRAINT DF_StockReceipts_ReceivedAt DEFAULT GETDATE(),
    delivery_note_ref  NVARCHAR(100)  NULL,
    note               NVARCHAR(500)  NULL,
    CONSTRAINT UQ_StockReceipts_Code     UNIQUE (receipt_code),
    CONSTRAINT FK_StockReceipts_IPO      FOREIGN KEY (ipo_id)              REFERENCES dbo.IPOs  (ipo_id),
    CONSTRAINT FK_StockReceipts_Keeper   FOREIGN KEY (warehouse_keeper_id) REFERENCES dbo.Users (user_id)
);
GO

-- Bảng: StockReceiptItems (Chi tiết kiểm định phân loại hàng)
IF OBJECT_ID('dbo.StockReceiptItems', 'U') IS NULL
CREATE TABLE dbo.StockReceiptItems (
    receipt_item_id     INT            IDENTITY(1,1) PRIMARY KEY,
    receipt_id          INT            NOT NULL,
    material_id         INT            NULL,
    material_name_other NVARCHAR(300)  NULL,
    qty_ordered         DECIMAL(18,4)  NOT NULL,
    qty_received        DECIMAL(18,4)  NOT NULL,
    qty_passed          DECIMAL(18,4)  NOT NULL,
    qty_failed          DECIMAL(18,4)  NOT NULL,
    photo_paths         NVARCHAR(MAX)  NULL,
    CONSTRAINT FK_StockReceiptItems_Receipt  FOREIGN KEY (receipt_id)  REFERENCES dbo.StockReceipts (receipt_id),
    CONSTRAINT FK_StockReceiptItems_Material FOREIGN KEY (material_id) REFERENCES dbo.Materials     (material_id),
    CONSTRAINT CK_StockReceiptItems_QtyLogic CHECK (
        qty_received >= 0 AND qty_passed >= 0 AND qty_failed >= 0
        AND qty_received = qty_passed + qty_failed
    ),
    CONSTRAINT CK_StockReceiptItems_MaterialCheck   CHECK (
        (material_id IS NOT NULL AND material_name_other IS NULL)
        OR (material_id IS NULL AND material_name_other IS NOT NULL)
    ),
    CONSTRAINT CK_StockReceiptItems_PhotoMandatory  CHECK (
        qty_failed = 0 OR photo_paths IS NOT NULL
    )
);
GO

-- Bảng: Inventory (Quản lý số dư tồn kho)
IF OBJECT_ID('dbo.Inventory', 'U') IS NULL
CREATE TABLE dbo.Inventory (
    inventory_id    INT           IDENTITY(1,1) PRIMARY KEY,
    branch_id       INT           NOT NULL,
    material_id     INT           NOT NULL,
    qty_on_hand     DECIMAL(18,4) NOT NULL CONSTRAINT DF_Inventory_OnHand     DEFAULT 0,
    qty_available   DECIMAL(18,4) NOT NULL CONSTRAINT DF_Inventory_Available  DEFAULT 0,
    qty_quarantine  DECIMAL(18,4) NOT NULL CONSTRAINT DF_Inventory_Quarantine DEFAULT 0,
    last_updated_at DATETIME2     NOT NULL CONSTRAINT DF_Inventory_UpdatedAt  DEFAULT GETDATE(),
    CONSTRAINT UQ_Inventory_BranchMaterial UNIQUE (branch_id, material_id),
    CONSTRAINT FK_Inventory_Branch   FOREIGN KEY (branch_id)   REFERENCES dbo.Branches  (branch_id),
    CONSTRAINT FK_Inventory_Material FOREIGN KEY (material_id) REFERENCES dbo.Materials (material_id),
    CONSTRAINT CK_Inventory_Min      CHECK (qty_on_hand >= 0 AND qty_available >= 0 AND qty_quarantine >= 0)
);
GO

-- Bảng: StockIssues (Phiếu xuất kho)
IF OBJECT_ID('dbo.StockIssues', 'U') IS NULL
CREATE TABLE dbo.StockIssues (
    issue_id           INT            IDENTITY(1,1) PRIMARY KEY,
    issue_code         NVARCHAR(30)   NOT NULL,
    pr_id              INT            NULL,
    dept_id            INT            NOT NULL,
    warehouse_keeper_id INT           NOT NULL,
    receiver_user_id   INT            NOT NULL,
    issued_at          DATETIME2      NOT NULL CONSTRAINT DF_StockIssues_IssuedAt DEFAULT GETDATE(),
    CONSTRAINT UQ_StockIssues_Code    UNIQUE (issue_code),
    CONSTRAINT FK_StockIssues_PR      FOREIGN KEY (pr_id)               REFERENCES dbo.PurchaseRequisitions (pr_id),
    CONSTRAINT FK_StockIssues_Dept    FOREIGN KEY (dept_id)             REFERENCES dbo.Departments          (dept_id),
    CONSTRAINT FK_StockIssues_Keeper  FOREIGN KEY (warehouse_keeper_id) REFERENCES dbo.Users                (user_id),
    CONSTRAINT FK_StockIssues_Receiver FOREIGN KEY (receiver_user_id)   REFERENCES dbo.Users                (user_id)
);
GO

-- Bảng: StockIssueItems (Chi tiết vật tư xuất kho)
IF OBJECT_ID('dbo.StockIssueItems', 'U') IS NULL
CREATE TABLE dbo.StockIssueItems (
    issue_item_id  INT            IDENTITY(1,1) PRIMARY KEY,
    issue_id       INT            NOT NULL,
    material_id    INT            NOT NULL,
    qty_issued     DECIMAL(18,4)  NOT NULL,
    quality_rating INT            NULL,
    CONSTRAINT FK_StockIssueItems_Issue    FOREIGN KEY (issue_id)    REFERENCES dbo.StockIssues (issue_id),
    CONSTRAINT FK_StockIssueItems_Material FOREIGN KEY (material_id) REFERENCES dbo.Materials   (material_id),
    CONSTRAINT CK_StockIssueItems_Qty     CHECK (qty_issued > 0),
    CONSTRAINT CK_StockIssueItems_Rating  CHECK (quality_rating IS NULL OR (quality_rating >= 1 AND quality_rating <= 5))
);
GO

-- Bảng: ReturnOrders (Đơn xuất trả hàng về NCC)
IF OBJECT_ID('dbo.ReturnOrders', 'U') IS NULL
CREATE TABLE dbo.ReturnOrders (
    return_id          INT            IDENTITY(1,1) PRIMARY KEY,
    return_code        NVARCHAR(30)   NOT NULL,
    supplier_id        INT            NOT NULL,
    receipt_id         INT            NOT NULL,
    created_by_user_id INT            NOT NULL,
    return_status      NVARCHAR(30)   NOT NULL CONSTRAINT DF_ReturnOrders_Status    DEFAULT 'DRAFT',
    created_at         DATETIME2      NOT NULL CONSTRAINT DF_ReturnOrders_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT UQ_ReturnOrders_Code     UNIQUE (return_code),
    CONSTRAINT FK_ReturnOrders_Supplier FOREIGN KEY (supplier_id)        REFERENCES dbo.Suppliers    (supplier_id),
    CONSTRAINT FK_ReturnOrders_Receipt  FOREIGN KEY (receipt_id)         REFERENCES dbo.StockReceipts(receipt_id),
    CONSTRAINT FK_ReturnOrders_Creator  FOREIGN KEY (created_by_user_id) REFERENCES dbo.Users        (user_id),
    CONSTRAINT CK_ReturnOrders_Status   CHECK (return_status IN ('DRAFT', 'SENT', 'RESOLVED'))
);
GO

-- Bảng: ReturnOrderItems (Chi tiết hàng xuất trả)
IF OBJECT_ID('dbo.ReturnOrderItems', 'U') IS NULL
CREATE TABLE dbo.ReturnOrderItems (
    return_item_id INT            IDENTITY(1,1) PRIMARY KEY,
    return_id      INT            NOT NULL,
    material_id    INT            NOT NULL,
    qty_returned   DECIMAL(18,4)  NOT NULL,
    reason         NVARCHAR(300)  NULL,
    CONSTRAINT FK_ReturnOrderItems_Return   FOREIGN KEY (return_id)   REFERENCES dbo.ReturnOrders (return_id),
    CONSTRAINT FK_ReturnOrderItems_Material FOREIGN KEY (material_id) REFERENCES dbo.Materials    (material_id),
    CONSTRAINT CK_ReturnOrderItems_Qty      CHECK (qty_returned > 0)
);
GO

-- ============================================================
-- MODULE 8: INVOICE & ĐỐI SOÁT TỰ ĐỘNG 3 CHIỀU
-- ============================================================

-- Bảng: Invoices (Hóa đơn tài chính đỏ)
IF OBJECT_ID('dbo.Invoices', 'U') IS NULL
CREATE TABLE dbo.Invoices (
    invoice_id         INT            IDENTITY(1,1) PRIMARY KEY,
    invoice_number     NVARCHAR(50)   NOT NULL,
    invoice_date       DATETIME2      NOT NULL,
    supplier_id        INT            NOT NULL,
    ipo_id             INT            NOT NULL,
    amount_before_tax  DECIMAL(18,2)  NOT NULL,
    tax_amount         DECIMAL(18,2)  NOT NULL,
    total_amount       DECIMAL(18,2)  NOT NULL,
    invoice_pdf_path   NVARCHAR(500)  NULL,
    matching_status    NVARCHAR(30)   NOT NULL CONSTRAINT DF_Invoices_MatchStatus  DEFAULT 'PENDING',
    is_overridden      BIT            NOT NULL CONSTRAINT DF_Invoices_IsOverridden DEFAULT 0,
    override_by_user_id INT           NULL,
    override_note      NVARCHAR(500)  NULL,
    created_at         DATETIME2      NOT NULL CONSTRAINT DF_Invoices_CreatedAt    DEFAULT GETDATE(),
    -- Chống trùng hóa đơn cùng NCC
    CONSTRAINT UQ_Invoices_NumberSupplier UNIQUE (invoice_number, supplier_id),
    CONSTRAINT FK_Invoices_Supplier       FOREIGN KEY (supplier_id)        REFERENCES dbo.Suppliers (supplier_id),
    CONSTRAINT FK_Invoices_IPO            FOREIGN KEY (ipo_id)             REFERENCES dbo.IPOs      (ipo_id),
    CONSTRAINT FK_Invoices_Override       FOREIGN KEY (override_by_user_id) REFERENCES dbo.Users    (user_id),
    CONSTRAINT CK_Invoices_Amounts        CHECK (total_amount = amount_before_tax + tax_amount),
    CONSTRAINT CK_Invoices_MatchStatus    CHECK (matching_status IN ('PENDING', 'MATCHED', 'MISMATCHED'))
);
GO

-- Bảng: InvoiceMatchingResults (Chi tiết kết quả đối soát 3 chiều)
IF OBJECT_ID('dbo.InvoiceMatchingResults', 'U') IS NULL
CREATE TABLE dbo.InvoiceMatchingResults (
    matching_id          INT            IDENTITY(1,1) PRIMARY KEY,
    invoice_id           INT            NOT NULL,
    ipo_item_id          INT            NOT NULL,
    receipt_item_id      INT            NOT NULL,
    qty_invoice          DECIMAL(18,4)  NOT NULL,
    qty_received_passed  DECIMAL(18,4)  NOT NULL,
    price_invoice        DECIMAL(18,2)  NOT NULL,
    price_ipo            DECIMAL(18,2)  NOT NULL,
    qty_diff             DECIMAL(18,4)  NOT NULL,
    price_diff           DECIMAL(18,2)  NOT NULL,
    is_error             BIT            NOT NULL CONSTRAINT DF_Matching_IsError DEFAULT 0,
    log_details_json     NVARCHAR(MAX)  NULL,
    CONSTRAINT FK_Matching_Invoice     FOREIGN KEY (invoice_id)     REFERENCES dbo.Invoices          (invoice_id),
    CONSTRAINT FK_Matching_IPOItem     FOREIGN KEY (ipo_item_id)    REFERENCES dbo.IPOItems          (ipo_item_id),
    CONSTRAINT FK_Matching_ReceiptItem FOREIGN KEY (receipt_item_id) REFERENCES dbo.StockReceiptItems (receipt_item_id)
);
GO

-- Bảng: PaymentRequests (Hồ sơ đề nghị thanh toán)
IF OBJECT_ID('dbo.PaymentRequests', 'U') IS NULL
CREATE TABLE dbo.PaymentRequests (
    payment_req_id    INT            IDENTITY(1,1) PRIMARY KEY,
    payment_req_code  NVARCHAR(30)   NOT NULL,
    invoice_id        INT            NOT NULL,
    applicant_user_id INT            NOT NULL,
    requested_amount  DECIMAL(18,2)  NOT NULL,
    payment_deadline  DATETIME2      NOT NULL,
    req_status        NVARCHAR(30)   NOT NULL CONSTRAINT DF_PaymentReq_Status    DEFAULT 'PENDING',
    created_at        DATETIME2      NOT NULL CONSTRAINT DF_PaymentReq_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT UQ_PaymentRequests_Code     UNIQUE (payment_req_code),
    CONSTRAINT FK_PaymentReq_Invoice       FOREIGN KEY (invoice_id)        REFERENCES dbo.Invoices (invoice_id),
    CONSTRAINT FK_PaymentReq_Applicant     FOREIGN KEY (applicant_user_id) REFERENCES dbo.Users    (user_id),
    CONSTRAINT CK_PaymentReq_Status        CHECK (req_status IN ('PENDING', 'APPROVED', 'PAID', 'REJECTED'))
);
GO

-- Bảng: CreditNotes (Chứng từ giảm trừ công nợ NCC) [v2.1]
IF OBJECT_ID('dbo.CreditNotes', 'U') IS NULL
CREATE TABLE dbo.CreditNotes (
    credit_note_id           INT            IDENTITY(1,1) PRIMARY KEY,
    credit_note_code         NVARCHAR(30)   NOT NULL,
    credit_note_number       NVARCHAR(50)   NOT NULL,
    supplier_id              INT            NOT NULL,
    invoice_id               INT            NOT NULL,
    return_id                INT            NULL,
    credit_amount_before_tax DECIMAL(18,2)  NOT NULL,
    credit_tax_amount        DECIMAL(18,2)  NOT NULL,
    credit_total_amount      DECIMAL(18,2)  NOT NULL,
    credit_date              DATETIME2      NOT NULL,
    reason                   NVARCHAR(500)  NOT NULL,
    credit_pdf_path          NVARCHAR(500)  NULL,
    applied_status           NVARCHAR(30)   NOT NULL CONSTRAINT DF_CreditNotes_Status    DEFAULT 'PENDING',
    applied_to_payment_id    INT            NULL,
    created_by_user_id       INT            NOT NULL,
    created_at               DATETIME2      NOT NULL CONSTRAINT DF_CreditNotes_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT UQ_CreditNotes_Code         UNIQUE (credit_note_code),
    CONSTRAINT FK_CreditNotes_Supplier     FOREIGN KEY (supplier_id)           REFERENCES dbo.Suppliers      (supplier_id),
    CONSTRAINT FK_CreditNotes_Invoice      FOREIGN KEY (invoice_id)            REFERENCES dbo.Invoices       (invoice_id),
    CONSTRAINT FK_CreditNotes_Return       FOREIGN KEY (return_id)             REFERENCES dbo.ReturnOrders   (return_id),
    CONSTRAINT FK_CreditNotes_Payment      FOREIGN KEY (applied_to_payment_id) REFERENCES dbo.PaymentRequests(payment_req_id),
    CONSTRAINT FK_CreditNotes_Creator      FOREIGN KEY (created_by_user_id)    REFERENCES dbo.Users          (user_id),
    CONSTRAINT CK_CreditNotes_Amounts      CHECK (credit_total_amount = credit_amount_before_tax + credit_tax_amount),
    CONSTRAINT CK_CreditNotes_AmountPositive CHECK (credit_total_amount > 0),
    CONSTRAINT CK_CreditNotes_Status       CHECK (applied_status IN ('PENDING', 'APPLIED', 'REFUNDED'))
);
GO

-- Bảng: DebitNotes (Chứng từ NCC điều chỉnh giảm giá) [v2.1]
IF OBJECT_ID('dbo.DebitNotes', 'U') IS NULL
CREATE TABLE dbo.DebitNotes (
    debit_note_id         INT            IDENTITY(1,1) PRIMARY KEY,
    debit_note_code       NVARCHAR(30)   NOT NULL,
    debit_note_number     NVARCHAR(50)   NOT NULL,
    supplier_id           INT            NOT NULL,
    invoice_id            INT            NOT NULL,
    debit_amount          DECIMAL(18,2)  NOT NULL,
    debit_date            DATETIME2      NOT NULL,
    reason                NVARCHAR(500)  NOT NULL,
    debit_pdf_path        NVARCHAR(500)  NULL,
    applied_status        NVARCHAR(30)   NOT NULL CONSTRAINT DF_DebitNotes_Status    DEFAULT 'PENDING',
    applied_to_payment_id INT            NULL,
    created_by_user_id    INT            NOT NULL,
    created_at            DATETIME2      NOT NULL CONSTRAINT DF_DebitNotes_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT UQ_DebitNotes_Code         UNIQUE (debit_note_code),
    CONSTRAINT FK_DebitNotes_Supplier     FOREIGN KEY (supplier_id)           REFERENCES dbo.Suppliers      (supplier_id),
    CONSTRAINT FK_DebitNotes_Invoice      FOREIGN KEY (invoice_id)            REFERENCES dbo.Invoices       (invoice_id),
    CONSTRAINT FK_DebitNotes_Payment      FOREIGN KEY (applied_to_payment_id) REFERENCES dbo.PaymentRequests(payment_req_id),
    CONSTRAINT FK_DebitNotes_Creator      FOREIGN KEY (created_by_user_id)    REFERENCES dbo.Users          (user_id),
    CONSTRAINT CK_DebitNotes_AmountPositive CHECK (debit_amount > 0),
    CONSTRAINT CK_DebitNotes_Status         CHECK (applied_status IN ('PENDING', 'APPLIED'))
);
GO

-- ============================================================
-- MODULE 9: CẤU HÌNH, THÔNG BÁO HỆ THỐNG & AUDIT TRAIL
-- ============================================================

-- Bảng: SystemConfigs (Tham số cấu hình động)
IF OBJECT_ID('dbo.SystemConfigs', 'U') IS NULL
CREATE TABLE dbo.SystemConfigs (
    config_id        INT            IDENTITY(1,1) PRIMARY KEY,
    config_key       NVARCHAR(50)   NOT NULL,
    config_value_json NVARCHAR(MAX) NOT NULL,
    description      NVARCHAR(300)  NULL,
    updated_at       DATETIME2      NOT NULL CONSTRAINT DF_SystemConfigs_UpdatedAt DEFAULT GETDATE(),
    CONSTRAINT UQ_SystemConfigs_Key UNIQUE (config_key)
);
GO

-- Bảng: AuditLogs (Nhật ký lưu vết thao tác — chỉ INSERT/SELECT)
IF OBJECT_ID('dbo.AuditLogs', 'U') IS NULL
CREATE TABLE dbo.AuditLogs (
    audit_id    INT            IDENTITY(1,1) PRIMARY KEY,
    event_type  NVARCHAR(50)   NOT NULL,
    object_type NVARCHAR(50)   NOT NULL,
    object_id   NVARCHAR(50)   NOT NULL,
    user_id     INT            NULL,
    ip_address  NVARCHAR(45)   NULL,
    old_values  NVARCHAR(MAX)  NULL,
    new_values  NVARCHAR(MAX)  NULL,
    created_at  DATETIME2      NOT NULL CONSTRAINT DF_AuditLogs_CreatedAt DEFAULT GETDATE(),
    CONSTRAINT FK_AuditLogs_User FOREIGN KEY (user_id) REFERENCES dbo.Users (user_id)
);
GO

-- Trigger bảo vệ AuditLogs: cấm UPDATE và DELETE
IF OBJECT_ID('dbo.TR_AuditLogs_PreventModify', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_AuditLogs_PreventModify;
GO
CREATE TRIGGER dbo.TR_AuditLogs_PreventModify
ON dbo.AuditLogs
AFTER UPDATE, DELETE
AS
BEGIN
    RAISERROR ('AuditLogs là bảng bảo vệ kiểm toán — không cho phép UPDATE hoặc DELETE.', 16, 1);
    ROLLBACK TRANSACTION;
END;
GO

-- Bảng: EmailTemplates (Mẫu thông điệp email/in-app) [v2.1]
IF OBJECT_ID('dbo.EmailTemplates', 'U') IS NULL
CREATE TABLE dbo.EmailTemplates (
    template_id              INT            IDENTITY(1,1) PRIMARY KEY,
    template_code            NVARCHAR(50)   NOT NULL,
    template_name            NVARCHAR(150)  NOT NULL,
    channel                  NVARCHAR(20)   NOT NULL,
    language                 NVARCHAR(10)   NOT NULL CONSTRAINT DF_EmailTemplates_Lang      DEFAULT 'vi',
    subject                  NVARCHAR(300)  NULL,
    body_html                NVARCHAR(MAX)  NULL,
    body_plain_text          NVARCHAR(MAX)  NULL,
    available_placeholders   NVARCHAR(MAX)  NULL,
    is_system                BIT            NOT NULL CONSTRAINT DF_EmailTemplates_IsSystem  DEFAULT 0,
    is_active                BIT            NOT NULL CONSTRAINT DF_EmailTemplates_IsActive  DEFAULT 1,
    last_updated_by_user_id  INT            NULL,
    created_at               DATETIME2      NOT NULL CONSTRAINT DF_EmailTemplates_CreatedAt DEFAULT GETDATE(),
    updated_at               DATETIME2      NULL,
    CONSTRAINT UQ_EmailTemplates_CodeLang   UNIQUE (template_code, language, channel),
    CONSTRAINT FK_EmailTemplates_UpdatedBy  FOREIGN KEY (last_updated_by_user_id) REFERENCES dbo.Users (user_id),
    CONSTRAINT CK_EmailTemplates_Channel    CHECK (channel IN ('EMAIL', 'IN_APP', 'SMS')),
    CONSTRAINT CK_EmailTemplates_BodyRequired CHECK (body_html IS NOT NULL OR body_plain_text IS NOT NULL)
);
GO

-- Trigger bảo vệ EmailTemplates is_system: cấm DELETE bản ghi hệ thống
IF OBJECT_ID('dbo.TR_EmailTemplates_PreventSystemDelete', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_EmailTemplates_PreventSystemDelete;
GO
CREATE TRIGGER dbo.TR_EmailTemplates_PreventSystemDelete
ON dbo.EmailTemplates
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM deleted WHERE is_system = 1)
    BEGIN
        RAISERROR ('Không được phép xóa EmailTemplate hệ thống (is_system = 1).', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    DELETE et FROM dbo.EmailTemplates et
    INNER JOIN deleted d ON et.template_id = d.template_id;
END;
GO

-- Bảng: Notifications (Hệ thống thông báo đẩy trong ứng dụng)
IF OBJECT_ID('dbo.Notifications', 'U') IS NULL
CREATE TABLE dbo.Notifications (
    notification_id   INT             IDENTITY(1,1) PRIMARY KEY,
    recipient_user_id INT             NOT NULL,
    notification_type NVARCHAR(50)    NOT NULL,
    title             NVARCHAR(300)   NOT NULL,
    body              NVARCHAR(1000)  NOT NULL,
    link_url          NVARCHAR(500)   NULL,
    is_read           BIT             NOT NULL CONSTRAINT DF_Notifications_IsRead   DEFAULT 0,
    read_at           DATETIME2       NULL,
    created_at        DATETIME2       NOT NULL CONSTRAINT DF_Notifications_CreatedAt DEFAULT GETDATE(),
    email_template_id INT             NULL,
    CONSTRAINT FK_Notifications_Recipient FOREIGN KEY (recipient_user_id) REFERENCES dbo.Users         (user_id),
    CONSTRAINT FK_Notifications_Template  FOREIGN KEY (email_template_id) REFERENCES dbo.EmailTemplates(template_id)
);
GO

-- ============================================================
-- MODULE 10: SUPPLIER EVALUATION (ĐÁNH GIÁ NCC ĐỊNH KỲ) [v2.1]
-- ============================================================

-- Bảng: SupplierEvaluations (Bản ghi đánh giá NCC theo kỳ)
IF OBJECT_ID('dbo.SupplierEvaluations', 'U') IS NULL
CREATE TABLE dbo.SupplierEvaluations (
    evaluation_id     INT             IDENTITY(1,1) PRIMARY KEY,
    supplier_id       INT             NOT NULL,
    period_type       NVARCHAR(20)    NOT NULL,
    period_value      NVARCHAR(20)    NOT NULL,
    period_start_date DATETIME2       NOT NULL,
    period_end_date   DATETIME2       NOT NULL,
    total_score       DECIMAL(5,2)    NOT NULL,
    rank              NVARCHAR(20)    NOT NULL,
    subjective_comment NVARCHAR(1000) NULL,
    is_finalized      BIT             NOT NULL CONSTRAINT DF_SupplierEval_IsFinalized DEFAULT 0,
    evaluator_user_id INT             NOT NULL,
    created_at        DATETIME2       NOT NULL CONSTRAINT DF_SupplierEval_CreatedAt  DEFAULT GETDATE(),
    finalized_at      DATETIME2       NULL,
    CONSTRAINT FK_SupplierEval_Supplier  FOREIGN KEY (supplier_id)       REFERENCES dbo.Suppliers (supplier_id),
    CONSTRAINT FK_SupplierEval_Evaluator FOREIGN KEY (evaluator_user_id) REFERENCES dbo.Users     (user_id),
    CONSTRAINT UQ_SupplierEvaluations_Period UNIQUE (supplier_id, period_type, period_value),
    CONSTRAINT CK_SupplierEvaluations_Score     CHECK (total_score >= 0 AND total_score <= 100),
    CONSTRAINT CK_SupplierEvaluations_Rank      CHECK (rank IN ('GOLD', 'SILVER', 'BRONZE', 'WARNING')),
    CONSTRAINT CK_SupplierEvaluations_PeriodType CHECK (period_type IN ('MONTH', 'QUARTER', 'YEAR')),
    CONSTRAINT CK_SupplierEvaluations_DateRange  CHECK (period_end_date > period_start_date)
);
GO

-- Bảng: SupplierEvaluationCriteria (Chi tiết điểm từng tiêu chí)
IF OBJECT_ID('dbo.SupplierEvaluationCriteria', 'U') IS NULL
CREATE TABLE dbo.SupplierEvaluationCriteria (
    criteria_id      INT            IDENTITY(1,1) PRIMARY KEY,
    evaluation_id    INT            NOT NULL,
    criteria_code    NVARCHAR(50)   NOT NULL,
    criteria_name    NVARCHAR(150)  NOT NULL,
    raw_score        DECIMAL(5,2)   NOT NULL,
    weight           DECIMAL(5,4)   NOT NULL,
    weighted_score   DECIMAL(7,4)   NOT NULL,
    data_source_json NVARCHAR(MAX)  NULL,
    notes            NVARCHAR(500)  NULL,
    CONSTRAINT FK_EvalCriteria_Evaluation  FOREIGN KEY (evaluation_id) REFERENCES dbo.SupplierEvaluations (evaluation_id),
    CONSTRAINT UQ_EvalCriteria_EvalCode    UNIQUE (evaluation_id, criteria_code),
    CONSTRAINT CK_EvalCriteria_RawScore    CHECK (raw_score  >= 0 AND raw_score  <= 100),
    CONSTRAINT CK_EvalCriteria_Weight      CHECK (weight     >= 0 AND weight     <= 1)
);
GO

-- ============================================================
-- INDEXES TỐI ƯU HIỆU NĂNG
-- ============================================================

-- 1. AuditLogs: kiểm toán theo dòng thời gian
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLogs_performance' AND object_id = OBJECT_ID('dbo.AuditLogs'))
    CREATE NONCLUSTERED INDEX IX_AuditLogs_performance
    ON dbo.AuditLogs (object_type, object_id, created_at);
GO

-- 2. Notifications: thông báo chưa đọc của người dùng
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Notifications_Unread' AND object_id = OBJECT_ID('dbo.Notifications'))
    CREATE NONCLUSTERED INDEX IX_Notifications_Unread
    ON dbo.Notifications (recipient_user_id, is_read);
GO

-- 3. PRItems: lọc trạng thái xử lý dòng hàng PR
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PRItems_Lookup' AND object_id = OBJECT_ID('dbo.PRItems'))
    CREATE NONCLUSTERED INDEX IX_PRItems_Lookup
    ON dbo.PRItems (pr_id, item_status);
GO

-- 4. IPOs: truy vấn phiên bản hiệu lực mới nhất
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_IPO_LatestVersion' AND object_id = OBJECT_ID('dbo.IPOs'))
    CREATE NONCLUSTERED INDEX IX_IPO_LatestVersion
    ON dbo.IPOs (ipo_code, is_latest, ipo_status);
GO

-- 5. Invoices: kế toán lọc hóa đơn lỗi chưa đối soát
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_InvoiceMatching_Run' AND object_id = OBJECT_ID('dbo.Invoices'))
    CREATE NONCLUSTERED INDEX IX_InvoiceMatching_Run
    ON dbo.Invoices (ipo_id, matching_status);
GO

-- 6. QuotationVersions: lịch sử phiên bản báo giá [v2.1]
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_QuotationVersions_Current' AND object_id = OBJECT_ID('dbo.QuotationVersions'))
    CREATE NONCLUSTERED INDEX IX_QuotationVersions_Current
    ON dbo.QuotationVersions (quotation_id, is_current, version_number);
GO

-- 7. CreditNotes: công nợ theo NCC và trạng thái [v2.1]
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CreditNotes_SupplierStatus' AND object_id = OBJECT_ID('dbo.CreditNotes'))
    CREATE NONCLUSTERED INDEX IX_CreditNotes_SupplierStatus
    ON dbo.CreditNotes (supplier_id, applied_status, credit_date);
GO

-- 8. DebitNotes: Debit Note theo NCC [v2.1]
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DebitNotes_SupplierStatus' AND object_id = OBJECT_ID('dbo.DebitNotes'))
    CREATE NONCLUSTERED INDEX IX_DebitNotes_SupplierStatus
    ON dbo.DebitNotes (supplier_id, applied_status, debit_date);
GO

-- 9. SupplierEvaluations: đánh giá NCC theo kỳ [v2.1]
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SupplierEvaluations_Period' AND object_id = OBJECT_ID('dbo.SupplierEvaluations'))
    CREATE NONCLUSTERED INDEX IX_SupplierEvaluations_Period
    ON dbo.SupplierEvaluations (supplier_id, period_type, period_value, is_finalized);
GO

-- 10. EmailTemplates: lookup theo template_code + ngôn ngữ + kênh [v2.1]
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EmailTemplates_Lookup' AND object_id = OBJECT_ID('dbo.EmailTemplates'))
    CREATE NONCLUSTERED INDEX IX_EmailTemplates_Lookup
    ON dbo.EmailTemplates (template_code, language, channel, is_active);
GO

-- ============================================================
-- FULL-TEXT SEARCH (TÌM KIẾM VĂN BẢN NÂNG CAO TIẾNG VIỆT)
-- ============================================================
-- Yêu cầu: SQL Server Full-Text Search feature phải được cài đặt.
-- Kiểm tra: SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled')

IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = 'ProcurementFTCatalog')
    CREATE FULLTEXT CATALOG ProcurementFTCatalog AS DEFAULT;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.fulltext_indexes
    WHERE object_id = OBJECT_ID('dbo.Materials')
)
BEGIN
    CREATE FULLTEXT INDEX ON dbo.Materials
    (
        material_name LANGUAGE 1066,   -- Vietnamese
        description   LANGUAGE 1066
    )
    KEY INDEX PK__Materials__MaterialId       -- Tên PK clustered index
    ON ProcurementFTCatalog
    WITH STOPLIST = SYSTEM;
END
GO

-- ============================================================
-- SEED DATA: EmailTemplates hệ thống (is_system = 1)
-- ============================================================
SET IDENTITY_INSERT dbo.EmailTemplates OFF;

MERGE dbo.EmailTemplates AS target
USING (VALUES
    ('QUOTATION_INVITATION_VN',   N'Mời báo giá NCC (Tiếng Việt)',         'EMAIL',  'vi',  N'Mời báo giá đơn hàng {{order_code}}',               N'<p>Kính gửi {{supplier_name}},<br>...</p>',            NULL,    N'[{"key":"supplier_name","desc":"Tên NCC"},{"key":"order_code","desc":"Mã đơn hàng"},{"key":"deadline","desc":"Hạn nộp"},{"key":"secure_link","desc":"Link báo giá"}]', 1),
    ('QUOTATION_REMINDER_VN',     N'Nhắc nhở báo giá NCC',                 'EMAIL',  'vi',  N'Nhắc: Chỉ còn {{hours_left}} giờ để nộp báo giá',  N'<p>Kính gửi {{supplier_name}},<br>...</p>',            NULL,    N'[{"key":"supplier_name","desc":"Tên NCC"},{"key":"hours_left","desc":"Số giờ còn lại"},{"key":"secure_link","desc":"Link báo giá"}]',                              1),
    ('URGENT_PR_ALERT',           N'Cảnh báo PR khẩn',                     'IN_APP', 'vi',  N'PR khẩn {{pr_code}} cần xử lý ngay',               N'Đơn PR khẩn từ {{requester_name}}: {{urgent_reason}}', NULL,    N'[{"key":"pr_code","desc":"Mã PR"},{"key":"requester_name","desc":"Người tạo PR"},{"key":"urgent_reason","desc":"Lý do khẩn"}]',                                1),
    ('IPO_PENDING_APPROVAL',      N'IPO chờ phê duyệt',                    'IN_APP', 'vi',  N'Đơn đặt hàng {{ipo_code}} chờ duyệt',              N'IPO {{ipo_code}} — {{total_amount}} VNĐ chờ phê duyệt',NULL,   N'[{"key":"ipo_code","desc":"Mã IPO"},{"key":"total_amount","desc":"Tổng tiền"},{"key":"approval_link","desc":"Link duyệt"}]',                                  1),
    ('IPO_APPROVED_NOTIFY_BUYER', N'Thông báo IPO được duyệt',             'IN_APP', 'vi',  NULL,                                                  N'IPO {{ipo_code}} đã được {{approver_name}} phê duyệt.',NULL,   N'[{"key":"ipo_code","desc":"Mã IPO"},{"key":"approver_name","desc":"Người duyệt"}]',                                                                         1),
    ('IPO_REJECTED_NOTIFY_BUYER', N'Thông báo IPO bị từ chối',             'IN_APP', 'vi',  N'IPO {{ipo_code}} bị từ chối',                       N'IPO {{ipo_code}} bị từ chối. Lý do: {{rejection_reason}}', NULL, N'[{"key":"ipo_code","desc":"Mã IPO"},{"key":"rejection_reason","desc":"Lý do từ chối"}]',                                                               1),
    ('STOCK_RECEIPT_NOTIFY_DEPT', N'Thông báo nhập kho',                   'IN_APP', 'vi',  NULL,                                                  N'{{material_name}} đã nhập kho: {{qty_received}} {{uom}} — giao cho {{dept_name}}', NULL, N'[{"key":"material_name","desc":"Tên vật tư"},{"key":"qty_received","desc":"SL nhập"},{"key":"dept_name","desc":"Phòng ban nhận"}]',                1),
    ('RETURN_ORDER_TO_SUPPLIER',  N'Thông báo trả hàng NCC',               'EMAIL',  'vi',  N'Thông báo hoàn trả hàng — {{return_code}}',         N'<p>Kính gửi {{supplier_name}},<br>...</p>',            NULL,    N'[{"key":"supplier_name","desc":"Tên NCC"},{"key":"return_code","desc":"Mã phiếu trả"},{"key":"reason","desc":"Lý do trả"}]',                                 1),
    ('INVOICE_MISMATCH_WARNING',  N'Cảnh báo sai lệch đối soát',           'IN_APP', 'vi',  N'Hóa đơn {{invoice_number}} có sai lệch đối soát',  N'Phát hiện sai lệch: {{discrepancy_details}}',          NULL,    N'[{"key":"invoice_number","desc":"Số hóa đơn"},{"key":"discrepancy_details","desc":"Chi tiết sai lệch"}]',                                                   1),
    ('PAYMENT_REQUEST_CREATED',   N'Thông báo tạo đề nghị thanh toán',     'IN_APP', 'vi',  NULL,                                                  N'Phiếu {{payment_req_code}} — {{amount}} VNĐ — hạn {{deadline}}', NULL, N'[{"key":"payment_req_code","desc":"Mã phiếu"},{"key":"amount","desc":"Số tiền"},{"key":"deadline","desc":"Hạn thanh toán"}]',                      1)
) AS source (template_code, template_name, channel, language, subject, body_plain_text, body_html, available_placeholders, is_system)
ON target.template_code = source.template_code
   AND target.language  = source.language
   AND target.channel   = source.channel
WHEN NOT MATCHED THEN
    INSERT (template_code, template_name, channel, language, subject, body_plain_text, body_html, available_placeholders, is_system, is_active)
    VALUES (source.template_code, source.template_name, source.channel, source.language,
            source.subject, source.body_plain_text, source.body_html, source.available_placeholders,
            source.is_system, 1);
GO

-- ============================================================
-- KIỂM TRA NHANH: Đếm số bảng đã tạo thành công
-- ============================================================
SELECT
    COUNT(*) AS total_tables_created,
    STRING_AGG(TABLE_NAME, ', ') WITHIN GROUP (ORDER BY TABLE_NAME) AS table_list
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND TABLE_CATALOG = DB_NAME();
GO

PRINT '============================================================';
PRINT 'ProcurementDB v2.1 — Script hoàn tất thành công!';
PRINT 'Tổng: 38 bảng + 2 Trigger bảo vệ + 10 Index + Full-Text Catalog';
PRINT '============================================================';
GO
