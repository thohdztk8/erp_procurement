/*
 Navicat Premium Dump SQL

 Source Server         : Proce local
 Source Server Type    : SQL Server
 Source Server Version : 16004260 (16.00.4260)
 Source Host           : localhost:1433
 Source Catalog        : ProcurementDB
 Source Schema         : dbo

 Target Server Type    : SQL Server
 Target Server Version : 16004260 (16.00.4260)
 File Encoding         : 65001

 Date: 02/06/2026 12:20:42
*/

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

-- ----------------------------
-- Table structure for ApprovalWorkflows
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[ApprovalWorkflows]') AND type IN ('U'))
	DROP TABLE [dbo].[ApprovalWorkflows]
GO

CREATE TABLE [dbo].[ApprovalWorkflows] (
  [workflow_id] int  IDENTITY(1,1) NOT NULL,
  [workflow_name] nvarchar(100) COLLATE Vietnamese_CI_AS  NOT NULL,
  [object_type] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [min_amount] decimal(18,2) DEFAULT 0 NOT NULL,
  [max_amount] decimal(18,2)  NULL,
  [dept_id] int  NULL,
  [is_active] bit DEFAULT 1 NOT NULL
)
GO

ALTER TABLE [dbo].[ApprovalWorkflows] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for ApprovalWorkflowSteps
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[ApprovalWorkflowSteps]') AND type IN ('U'))
	DROP TABLE [dbo].[ApprovalWorkflowSteps]
GO

CREATE TABLE [dbo].[ApprovalWorkflowSteps] (
  [step_id] int  IDENTITY(1,1) NOT NULL,
  [workflow_id] int  NOT NULL,
  [step_sequence] int  NOT NULL,
  [role_id] int  NOT NULL
)
GO

ALTER TABLE [dbo].[ApprovalWorkflowSteps] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for AuditLogs
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditLogs]') AND type IN ('U'))
	DROP TABLE [dbo].[AuditLogs]
GO

CREATE TABLE [dbo].[AuditLogs] (
  [audit_id] int  IDENTITY(1,1) NOT NULL,
  [event_type] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [object_type] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [object_id] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [user_id] int  NULL,
  [ip_address] nvarchar(45) COLLATE Vietnamese_CI_AS  NULL,
  [old_values] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [new_values] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[AuditLogs] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for auth_group
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[auth_group]') AND type IN ('U'))
	DROP TABLE [dbo].[auth_group]
GO

CREATE TABLE [dbo].[auth_group] (
  [id] int  IDENTITY(1,1) NOT NULL,
  [name] nvarchar(150) COLLATE Vietnamese_CI_AS  NOT NULL
)
GO

ALTER TABLE [dbo].[auth_group] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for auth_group_permissions
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[auth_group_permissions]') AND type IN ('U'))
	DROP TABLE [dbo].[auth_group_permissions]
GO

CREATE TABLE [dbo].[auth_group_permissions] (
  [id] bigint  IDENTITY(1,1) NOT NULL,
  [group_id] int  NOT NULL,
  [permission_id] int  NOT NULL
)
GO

ALTER TABLE [dbo].[auth_group_permissions] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for auth_permission
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[auth_permission]') AND type IN ('U'))
	DROP TABLE [dbo].[auth_permission]
GO

CREATE TABLE [dbo].[auth_permission] (
  [id] int  IDENTITY(1,1) NOT NULL,
  [name] nvarchar(255) COLLATE Vietnamese_CI_AS  NOT NULL,
  [content_type_id] int  NOT NULL,
  [codename] nvarchar(100) COLLATE Vietnamese_CI_AS  NOT NULL
)
GO

ALTER TABLE [dbo].[auth_permission] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Branches
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Branches]') AND type IN ('U'))
	DROP TABLE [dbo].[Branches]
GO

CREATE TABLE [dbo].[Branches] (
  [branch_id] int  IDENTITY(1,1) NOT NULL,
  [branch_code] nvarchar(20) COLLATE Vietnamese_CI_AS  NOT NULL,
  [branch_name] nvarchar(200) COLLATE Vietnamese_CI_AS  NOT NULL,
  [address] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [is_active] bit DEFAULT 1 NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL,
  [updated_at] datetime2(7)  NULL
)
GO

ALTER TABLE [dbo].[Branches] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for CartPRItems
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[CartPRItems]') AND type IN ('U'))
	DROP TABLE [dbo].[CartPRItems]
GO

CREATE TABLE [dbo].[CartPRItems] (
  [cart_id] int  NOT NULL,
  [pr_item_id] int  NOT NULL,
  [qty_in_cart] decimal(18,4)  NOT NULL,
  [added_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[CartPRItems] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Carts
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Carts]') AND type IN ('U'))
	DROP TABLE [dbo].[Carts]
GO

CREATE TABLE [dbo].[Carts] (
  [cart_id] int  IDENTITY(1,1) NOT NULL,
  [cart_title] nvarchar(150) COLLATE Vietnamese_CI_AS  NOT NULL,
  [buyer_user_id] int  NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[Carts] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for CreditNotes
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[CreditNotes]') AND type IN ('U'))
	DROP TABLE [dbo].[CreditNotes]
GO

CREATE TABLE [dbo].[CreditNotes] (
  [credit_note_id] int  IDENTITY(1,1) NOT NULL,
  [credit_note_code] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [credit_note_number] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [supplier_id] int  NOT NULL,
  [invoice_id] int  NOT NULL,
  [return_id] int  NULL,
  [credit_amount_before_tax] decimal(18,2)  NOT NULL,
  [credit_tax_amount] decimal(18,2)  NOT NULL,
  [credit_total_amount] decimal(18,2)  NOT NULL,
  [credit_date] datetime2(7)  NOT NULL,
  [reason] nvarchar(500) COLLATE Vietnamese_CI_AS  NOT NULL,
  [credit_pdf_path] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [applied_status] nvarchar(30) COLLATE Vietnamese_CI_AS DEFAULT 'PENDING' NOT NULL,
  [applied_to_payment_id] int  NULL,
  [created_by_user_id] int  NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[CreditNotes] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for DebitNotes
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[DebitNotes]') AND type IN ('U'))
	DROP TABLE [dbo].[DebitNotes]
GO

CREATE TABLE [dbo].[DebitNotes] (
  [debit_note_id] int  IDENTITY(1,1) NOT NULL,
  [debit_note_code] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [debit_note_number] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [supplier_id] int  NOT NULL,
  [invoice_id] int  NOT NULL,
  [debit_amount] decimal(18,2)  NOT NULL,
  [debit_date] datetime2(7)  NOT NULL,
  [reason] nvarchar(500) COLLATE Vietnamese_CI_AS  NOT NULL,
  [debit_pdf_path] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [applied_status] nvarchar(30) COLLATE Vietnamese_CI_AS DEFAULT 'PENDING' NOT NULL,
  [applied_to_payment_id] int  NULL,
  [created_by_user_id] int  NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[DebitNotes] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Departments
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Departments]') AND type IN ('U'))
	DROP TABLE [dbo].[Departments]
GO

CREATE TABLE [dbo].[Departments] (
  [dept_id] int  IDENTITY(1,1) NOT NULL,
  [dept_code] nvarchar(20) COLLATE Vietnamese_CI_AS  NOT NULL,
  [dept_name] nvarchar(200) COLLATE Vietnamese_CI_AS  NOT NULL,
  [branch_id] int  NULL,
  [parent_dept_id] int  NULL,
  [is_active] bit DEFAULT 1 NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[Departments] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for django_admin_log
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[django_admin_log]') AND type IN ('U'))
	DROP TABLE [dbo].[django_admin_log]
GO

CREATE TABLE [dbo].[django_admin_log] (
  [id] int  IDENTITY(1,1) NOT NULL,
  [action_time] datetimeoffset(7)  NOT NULL,
  [object_id] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [object_repr] nvarchar(200) COLLATE Vietnamese_CI_AS  NOT NULL,
  [action_flag] smallint  NOT NULL,
  [change_message] nvarchar(max) COLLATE Vietnamese_CI_AS  NOT NULL,
  [content_type_id] int  NULL,
  [user_id] int  NOT NULL
)
GO

ALTER TABLE [dbo].[django_admin_log] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for django_celery_results_chordcounter
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[django_celery_results_chordcounter]') AND type IN ('U'))
	DROP TABLE [dbo].[django_celery_results_chordcounter]
GO

CREATE TABLE [dbo].[django_celery_results_chordcounter] (
  [id] int  IDENTITY(1,1) NOT NULL,
  [group_id] nvarchar(255) COLLATE Vietnamese_CI_AS  NOT NULL,
  [sub_tasks] nvarchar(max) COLLATE Vietnamese_CI_AS  NOT NULL,
  [count] int  NOT NULL
)
GO

ALTER TABLE [dbo].[django_celery_results_chordcounter] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for django_celery_results_groupresult
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[django_celery_results_groupresult]') AND type IN ('U'))
	DROP TABLE [dbo].[django_celery_results_groupresult]
GO

CREATE TABLE [dbo].[django_celery_results_groupresult] (
  [id] int  IDENTITY(1,1) NOT NULL,
  [group_id] nvarchar(255) COLLATE Vietnamese_CI_AS  NOT NULL,
  [date_created] datetimeoffset(7)  NOT NULL,
  [date_done] datetimeoffset(7)  NOT NULL,
  [content_type] nvarchar(128) COLLATE Vietnamese_CI_AS  NOT NULL,
  [content_encoding] nvarchar(64) COLLATE Vietnamese_CI_AS  NOT NULL,
  [result] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL
)
GO

ALTER TABLE [dbo].[django_celery_results_groupresult] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for django_celery_results_taskresult
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[django_celery_results_taskresult]') AND type IN ('U'))
	DROP TABLE [dbo].[django_celery_results_taskresult]
GO

CREATE TABLE [dbo].[django_celery_results_taskresult] (
  [id] int  IDENTITY(1,1) NOT NULL,
  [task_id] nvarchar(255) COLLATE Vietnamese_CI_AS  NOT NULL,
  [status] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [content_type] nvarchar(128) COLLATE Vietnamese_CI_AS  NOT NULL,
  [content_encoding] nvarchar(64) COLLATE Vietnamese_CI_AS  NOT NULL,
  [result] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [date_done] datetimeoffset(7)  NOT NULL,
  [traceback] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [meta] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [task_args] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [task_kwargs] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [task_name] nvarchar(255) COLLATE Vietnamese_CI_AS  NULL,
  [worker] nvarchar(100) COLLATE Vietnamese_CI_AS  NULL,
  [date_created] datetimeoffset(7)  NOT NULL,
  [periodic_task_name] nvarchar(255) COLLATE Vietnamese_CI_AS  NULL
)
GO

ALTER TABLE [dbo].[django_celery_results_taskresult] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for django_content_type
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[django_content_type]') AND type IN ('U'))
	DROP TABLE [dbo].[django_content_type]
GO

CREATE TABLE [dbo].[django_content_type] (
  [id] int  IDENTITY(1,1) NOT NULL,
  [app_label] nvarchar(100) COLLATE Vietnamese_CI_AS  NOT NULL,
  [model] nvarchar(100) COLLATE Vietnamese_CI_AS  NOT NULL
)
GO

ALTER TABLE [dbo].[django_content_type] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for django_migrations
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[django_migrations]') AND type IN ('U'))
	DROP TABLE [dbo].[django_migrations]
GO

CREATE TABLE [dbo].[django_migrations] (
  [id] bigint  IDENTITY(1,1) NOT NULL,
  [app] nvarchar(255) COLLATE Vietnamese_CI_AS  NOT NULL,
  [name] nvarchar(255) COLLATE Vietnamese_CI_AS  NOT NULL,
  [applied] datetimeoffset(7)  NOT NULL
)
GO

ALTER TABLE [dbo].[django_migrations] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for django_session
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[django_session]') AND type IN ('U'))
	DROP TABLE [dbo].[django_session]
GO

CREATE TABLE [dbo].[django_session] (
  [session_key] nvarchar(40) COLLATE Vietnamese_CI_AS  NOT NULL,
  [session_data] nvarchar(max) COLLATE Vietnamese_CI_AS  NOT NULL,
  [expire_date] datetimeoffset(7)  NOT NULL
)
GO

ALTER TABLE [dbo].[django_session] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for DocumentApprovalProgress
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[DocumentApprovalProgress]') AND type IN ('U'))
	DROP TABLE [dbo].[DocumentApprovalProgress]
GO

CREATE TABLE [dbo].[DocumentApprovalProgress] (
  [progress_id] int  IDENTITY(1,1) NOT NULL,
  [document_type] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [document_id] int  NOT NULL,
  [step_sequence] int  NOT NULL,
  [approver_user_id] int  NULL,
  [approval_status] nvarchar(20) COLLATE Vietnamese_CI_AS DEFAULT 'PENDING' NOT NULL,
  [comment] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [action_date] datetime2(7)  NULL
)
GO

ALTER TABLE [dbo].[DocumentApprovalProgress] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for EmailTemplates
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[EmailTemplates]') AND type IN ('U'))
	DROP TABLE [dbo].[EmailTemplates]
GO

CREATE TABLE [dbo].[EmailTemplates] (
  [template_id] int  IDENTITY(1,1) NOT NULL,
  [template_code] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [template_name] nvarchar(150) COLLATE Vietnamese_CI_AS  NOT NULL,
  [channel] nvarchar(20) COLLATE Vietnamese_CI_AS  NOT NULL,
  [language] nvarchar(10) COLLATE Vietnamese_CI_AS DEFAULT 'vi' NOT NULL,
  [subject] nvarchar(300) COLLATE Vietnamese_CI_AS  NULL,
  [body_html] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [body] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [available_placeholders] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [is_system] bit DEFAULT 0 NOT NULL,
  [is_active] bit DEFAULT 1 NOT NULL,
  [last_updated_by_user_id] int  NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL,
  [updated_at] datetime2(7)  NULL
)
GO

ALTER TABLE [dbo].[EmailTemplates] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Inventory
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Inventory]') AND type IN ('U'))
	DROP TABLE [dbo].[Inventory]
GO

CREATE TABLE [dbo].[Inventory] (
  [inventory_id] int  IDENTITY(1,1) NOT NULL,
  [branch_id] int  NOT NULL,
  [material_id] int  NOT NULL,
  [qty_on_hand] decimal(18,4) DEFAULT 0 NOT NULL,
  [qty_available] decimal(18,4) DEFAULT 0 NOT NULL,
  [qty_quarantine] decimal(18,4) DEFAULT 0 NOT NULL,
  [last_updated_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[Inventory] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for InvoiceMatchingResults
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[InvoiceMatchingResults]') AND type IN ('U'))
	DROP TABLE [dbo].[InvoiceMatchingResults]
GO

CREATE TABLE [dbo].[InvoiceMatchingResults] (
  [matching_id] int  IDENTITY(1,1) NOT NULL,
  [invoice_id] int  NOT NULL,
  [ipo_item_id] int  NOT NULL,
  [receipt_item_id] int  NOT NULL,
  [qty_invoice] decimal(18,4)  NOT NULL,
  [qty_received_passed] decimal(18,4)  NOT NULL,
  [price_invoice] decimal(18,2)  NOT NULL,
  [price_ipo] decimal(18,2)  NOT NULL,
  [qty_diff] decimal(18,4)  NOT NULL,
  [price_diff] decimal(18,2)  NOT NULL,
  [is_error] bit DEFAULT 0 NOT NULL,
  [log_details_json] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL
)
GO

ALTER TABLE [dbo].[InvoiceMatchingResults] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Invoices
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Invoices]') AND type IN ('U'))
	DROP TABLE [dbo].[Invoices]
GO

CREATE TABLE [dbo].[Invoices] (
  [invoice_id] int  IDENTITY(1,1) NOT NULL,
  [invoice_number] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [invoice_date] datetime2(7)  NOT NULL,
  [supplier_id] int  NOT NULL,
  [ipo_id] int  NOT NULL,
  [amount_before_tax] decimal(18,2)  NOT NULL,
  [tax_amount] decimal(18,2)  NOT NULL,
  [total_amount] decimal(18,2)  NOT NULL,
  [invoice_pdf_path] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [matching_status] nvarchar(30) COLLATE Vietnamese_CI_AS DEFAULT 'PENDING' NOT NULL,
  [is_overridden] bit DEFAULT 0 NOT NULL,
  [override_by_user_id] int  NULL,
  [override_note] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[Invoices] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for IPOItems
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[IPOItems]') AND type IN ('U'))
	DROP TABLE [dbo].[IPOItems]
GO

CREATE TABLE [dbo].[IPOItems] (
  [ipo_item_id] int  IDENTITY(1,1) NOT NULL,
  [ipo_id] int  NOT NULL,
  [order_item_id] int  NOT NULL,
  [qty_final] decimal(18,4)  NOT NULL,
  [unit_price_final] decimal(18,2)  NOT NULL,
  [item_total_amount] decimal(18,2)  NOT NULL
)
GO

ALTER TABLE [dbo].[IPOItems] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for IPOs
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[IPOs]') AND type IN ('U'))
	DROP TABLE [dbo].[IPOs]
GO

CREATE TABLE [dbo].[IPOs] (
  [ipo_id] int  IDENTITY(1,1) NOT NULL,
  [ipo_code] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [version] int DEFAULT 1 NOT NULL,
  [is_latest] bit DEFAULT 1 NOT NULL,
  [order_id] int  NOT NULL,
  [supplier_id] int  NOT NULL,
  [buyer_user_id] int  NOT NULL,
  [total_amount] decimal(18,2)  NOT NULL,
  [ipo_status] nvarchar(30) COLLATE Vietnamese_CI_AS DEFAULT 'DRAFT' NOT NULL,
  [signed_pdf_path] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL,
  [updated_at] datetime2(7)  NULL
)
GO

ALTER TABLE [dbo].[IPOs] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for MaterialCategories
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[MaterialCategories]') AND type IN ('U'))
	DROP TABLE [dbo].[MaterialCategories]
GO

CREATE TABLE [dbo].[MaterialCategories] (
  [category_id] int  IDENTITY(1,1) NOT NULL,
  [category_code] nvarchar(20) COLLATE Vietnamese_CI_AS  NOT NULL,
  [category_name] nvarchar(150) COLLATE Vietnamese_CI_AS  NOT NULL,
  [is_active] bit DEFAULT 1 NOT NULL
)
GO

ALTER TABLE [dbo].[MaterialCategories] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Materials
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Materials]') AND type IN ('U'))
	DROP TABLE [dbo].[Materials]
GO

CREATE TABLE [dbo].[Materials] (
  [material_id] int  IDENTITY(1,1) NOT NULL,
  [material_code] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [material_name] nvarchar(300) COLLATE Vietnamese_CI_AS  NOT NULL,
  [category_id] int  NULL,
  [uom] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [min_stock_level] decimal(18,4) DEFAULT 0 NOT NULL,
  [description] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [is_other] bit DEFAULT 0 NOT NULL,
  [is_active] bit DEFAULT 1 NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[Materials] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Notifications
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Notifications]') AND type IN ('U'))
	DROP TABLE [dbo].[Notifications]
GO

CREATE TABLE [dbo].[Notifications] (
  [notification_id] int  IDENTITY(1,1) NOT NULL,
  [recipient_user_id] int  NOT NULL,
  [notification_type] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [title] nvarchar(300) COLLATE Vietnamese_CI_AS  NOT NULL,
  [body] nvarchar(1000) COLLATE Vietnamese_CI_AS  NOT NULL,
  [link_url] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [is_read] bit DEFAULT 0 NOT NULL,
  [read_at] datetime2(7)  NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL,
  [email_template_id] int  NULL
)
GO

ALTER TABLE [dbo].[Notifications] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for OrderItemPRLinks
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[OrderItemPRLinks]') AND type IN ('U'))
	DROP TABLE [dbo].[OrderItemPRLinks]
GO

CREATE TABLE [dbo].[OrderItemPRLinks] (
  [order_item_id] int  NOT NULL,
  [pr_item_id] int  NOT NULL,
  [qty_linked] decimal(18,4)  NOT NULL
)
GO

ALTER TABLE [dbo].[OrderItemPRLinks] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for OrderItems
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[OrderItems]') AND type IN ('U'))
	DROP TABLE [dbo].[OrderItems]
GO

CREATE TABLE [dbo].[OrderItems] (
  [order_item_id] int  IDENTITY(1,1) NOT NULL,
  [order_id] int  NOT NULL,
  [material_id] int  NULL,
  [material_name_other] nvarchar(300) COLLATE Vietnamese_CI_AS  NULL,
  [qty_total_ordered] decimal(18,4)  NOT NULL
)
GO

ALTER TABLE [dbo].[OrderItems] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Orders
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Orders]') AND type IN ('U'))
	DROP TABLE [dbo].[Orders]
GO

CREATE TABLE [dbo].[Orders] (
  [order_id] int  IDENTITY(1,1) NOT NULL,
  [order_code] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [buyer_user_id] int  NOT NULL,
  [order_status] nvarchar(30) COLLATE Vietnamese_CI_AS DEFAULT 'DRAFT' NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[Orders] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for OrderSuppliers
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[OrderSuppliers]') AND type IN ('U'))
	DROP TABLE [dbo].[OrderSuppliers]
GO

CREATE TABLE [dbo].[OrderSuppliers] (
  [order_id] int  NOT NULL,
  [supplier_id] int  NOT NULL,
  [assigned_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[OrderSuppliers] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for PaymentRequests
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[PaymentRequests]') AND type IN ('U'))
	DROP TABLE [dbo].[PaymentRequests]
GO

CREATE TABLE [dbo].[PaymentRequests] (
  [payment_req_id] int  IDENTITY(1,1) NOT NULL,
  [payment_req_code] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [invoice_id] int  NOT NULL,
  [applicant_user_id] int  NOT NULL,
  [requested_amount] decimal(18,2)  NOT NULL,
  [payment_deadline] datetime2(7)  NOT NULL,
  [req_status] nvarchar(30) COLLATE Vietnamese_CI_AS DEFAULT 'PENDING' NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[PaymentRequests] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Permissions
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Permissions]') AND type IN ('U'))
	DROP TABLE [dbo].[Permissions]
GO

CREATE TABLE [dbo].[Permissions] (
  [permission_id] int  IDENTITY(1,1) NOT NULL,
  [permission_code] nvarchar(100) COLLATE Vietnamese_CI_AS  NOT NULL,
  [permission_name] nvarchar(150) COLLATE Vietnamese_CI_AS  NOT NULL,
  [module_group] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL
)
GO

ALTER TABLE [dbo].[Permissions] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for PRItems
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[PRItems]') AND type IN ('U'))
	DROP TABLE [dbo].[PRItems]
GO

CREATE TABLE [dbo].[PRItems] (
  [pr_item_id] int  IDENTITY(1,1) NOT NULL,
  [pr_id] int  NOT NULL,
  [material_id] int  NULL,
  [material_name_other] nvarchar(300) COLLATE Vietnamese_CI_AS  NULL,
  [qty_requested] decimal(18,4)  NOT NULL,
  [qty_ordered] decimal(18,4) DEFAULT 0 NOT NULL,
  [qty_received] decimal(18,4) DEFAULT 0 NOT NULL,
  [estimated_unit_price] decimal(18,2) DEFAULT 0 NOT NULL,
  [required_deadline] datetime2(7)  NOT NULL,
  [item_status] nvarchar(30) COLLATE Vietnamese_CI_AS DEFAULT 'PENDING' NOT NULL
)
GO

ALTER TABLE [dbo].[PRItems] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for PRStatusHistory
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[PRStatusHistory]') AND type IN ('U'))
	DROP TABLE [dbo].[PRStatusHistory]
GO

CREATE TABLE [dbo].[PRStatusHistory] (
  [history_id] int  IDENTITY(1,1) NOT NULL,
  [pr_id] int  NOT NULL,
  [from_status] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [to_status] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [changed_by_user_id] int  NOT NULL,
  [note] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [changed_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[PRStatusHistory] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for PurchaseRequisitions
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[PurchaseRequisitions]') AND type IN ('U'))
	DROP TABLE [dbo].[PurchaseRequisitions]
GO

CREATE TABLE [dbo].[PurchaseRequisitions] (
  [pr_id] int  IDENTITY(1,1) NOT NULL,
  [pr_code] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [requester_user_id] int  NOT NULL,
  [branch_id] int  NOT NULL,
  [dept_id] int  NOT NULL,
  [priority_level] nvarchar(20) COLLATE Vietnamese_CI_AS DEFAULT 'NORMAL' NOT NULL,
  [urgent_reason] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [urgency_impact] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [pr_status] nvarchar(30) COLLATE Vietnamese_CI_AS DEFAULT 'DRAFT' NOT NULL,
  [total_estimated_amount] decimal(18,2) DEFAULT 0 NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL,
  [updated_at] datetime2(7)  NULL
)
GO

ALTER TABLE [dbo].[PurchaseRequisitions] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for QuotationItems
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotationItems]') AND type IN ('U'))
	DROP TABLE [dbo].[QuotationItems]
GO

CREATE TABLE [dbo].[QuotationItems] (
  [q_item_id] int  IDENTITY(1,1) NOT NULL,
  [quotation_id] int  NOT NULL,
  [order_item_id] int  NOT NULL,
  [quoted_unit_price] decimal(18,2)  NOT NULL,
  [supplier_note] nvarchar(300) COLLATE Vietnamese_CI_AS  NULL
)
GO

ALTER TABLE [dbo].[QuotationItems] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for QuotationRequests
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotationRequests]') AND type IN ('U'))
	DROP TABLE [dbo].[QuotationRequests]
GO

CREATE TABLE [dbo].[QuotationRequests] (
  [q_request_id] int  IDENTITY(1,1) NOT NULL,
  [order_id] int  NOT NULL,
  [supplier_id] int  NOT NULL,
  [deadline_submission] datetime2(7)  NOT NULL,
  [sent_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[QuotationRequests] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Quotations
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Quotations]') AND type IN ('U'))
	DROP TABLE [dbo].[Quotations]
GO

CREATE TABLE [dbo].[Quotations] (
  [quotation_id] int  IDENTITY(1,1) NOT NULL,
  [q_request_id] int  NOT NULL,
  [supplier_id] int  NOT NULL,
  [submitted_at] datetime2(7) DEFAULT getdate() NOT NULL,
  [delivery_lead_time_days] int  NOT NULL,
  [payment_terms_note] nvarchar(200) COLLATE Vietnamese_CI_AS  NULL,
  [total_quote_amount] decimal(18,2) DEFAULT 0 NOT NULL,
  [is_selected] bit DEFAULT 0 NOT NULL
)
GO

ALTER TABLE [dbo].[Quotations] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for QuotationTokens
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotationTokens]') AND type IN ('U'))
	DROP TABLE [dbo].[QuotationTokens]
GO

CREATE TABLE [dbo].[QuotationTokens] (
  [token_id] int  IDENTITY(1,1) NOT NULL,
  [q_request_id] int  NOT NULL,
  [token] nvarchar(128) COLLATE Vietnamese_CI_AS  NOT NULL,
  [expires_at] datetime2(7)  NOT NULL,
  [is_used] bit DEFAULT 0 NOT NULL,
  [used_at] datetime2(7)  NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[QuotationTokens] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for QuotationVersions
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[QuotationVersions]') AND type IN ('U'))
	DROP TABLE [dbo].[QuotationVersions]
GO

CREATE TABLE [dbo].[QuotationVersions] (
  [version_id] int  IDENTITY(1,1) NOT NULL,
  [quotation_id] int  NOT NULL,
  [version_number] int  NOT NULL,
  [is_current] bit DEFAULT 0 NOT NULL,
  [snapshot_total_amount] decimal(18,2)  NOT NULL,
  [snapshot_lead_time_days] int  NOT NULL,
  [snapshot_payment_terms] nvarchar(200) COLLATE Vietnamese_CI_AS  NULL,
  [snapshot_items_json] nvarchar(max) COLLATE Vietnamese_CI_AS  NOT NULL,
  [submitted_at] datetime2(7) DEFAULT getdate() NOT NULL,
  [submitted_ip] nvarchar(45) COLLATE Vietnamese_CI_AS  NULL,
  [change_summary] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL
)
GO

ALTER TABLE [dbo].[QuotationVersions] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for ReturnOrderItems
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[ReturnOrderItems]') AND type IN ('U'))
	DROP TABLE [dbo].[ReturnOrderItems]
GO

CREATE TABLE [dbo].[ReturnOrderItems] (
  [return_item_id] int  IDENTITY(1,1) NOT NULL,
  [return_id] int  NOT NULL,
  [material_id] int  NOT NULL,
  [qty_returned] decimal(18,4)  NOT NULL,
  [reason] nvarchar(300) COLLATE Vietnamese_CI_AS  NULL
)
GO

ALTER TABLE [dbo].[ReturnOrderItems] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for ReturnOrders
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[ReturnOrders]') AND type IN ('U'))
	DROP TABLE [dbo].[ReturnOrders]
GO

CREATE TABLE [dbo].[ReturnOrders] (
  [return_id] int  IDENTITY(1,1) NOT NULL,
  [return_code] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [supplier_id] int  NOT NULL,
  [receipt_id] int  NOT NULL,
  [created_by_user_id] int  NOT NULL,
  [return_status] nvarchar(30) COLLATE Vietnamese_CI_AS DEFAULT 'DRAFT' NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[ReturnOrders] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for RolePermissions
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[RolePermissions]') AND type IN ('U'))
	DROP TABLE [dbo].[RolePermissions]
GO

CREATE TABLE [dbo].[RolePermissions] (
  [role_permission_id] int  IDENTITY(1,1) NOT NULL,
  [role_id] int  NOT NULL,
  [permission_id] int  NOT NULL,
  [assigned_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[RolePermissions] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Roles
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND type IN ('U'))
	DROP TABLE [dbo].[Roles]
GO

CREATE TABLE [dbo].[Roles] (
  [role_id] int  IDENTITY(1,1) NOT NULL,
  [role_code] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [role_name] nvarchar(100) COLLATE Vietnamese_CI_AS  NOT NULL,
  [description] nvarchar(300) COLLATE Vietnamese_CI_AS  NULL,
  [is_active] bit DEFAULT 1 NOT NULL
)
GO

ALTER TABLE [dbo].[Roles] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for StockIssueItems
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[StockIssueItems]') AND type IN ('U'))
	DROP TABLE [dbo].[StockIssueItems]
GO

CREATE TABLE [dbo].[StockIssueItems] (
  [issue_item_id] int  IDENTITY(1,1) NOT NULL,
  [issue_id] int  NOT NULL,
  [material_id] int  NOT NULL,
  [qty_issued] decimal(18,4)  NOT NULL,
  [quality_rating] int  NULL
)
GO

ALTER TABLE [dbo].[StockIssueItems] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for StockIssues
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[StockIssues]') AND type IN ('U'))
	DROP TABLE [dbo].[StockIssues]
GO

CREATE TABLE [dbo].[StockIssues] (
  [issue_id] int  IDENTITY(1,1) NOT NULL,
  [issue_code] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [pr_id] int  NULL,
  [dept_id] int  NOT NULL,
  [warehouse_keeper_id] int  NOT NULL,
  [receiver_user_id] int  NOT NULL,
  [issued_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[StockIssues] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for StockReceiptItems
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[StockReceiptItems]') AND type IN ('U'))
	DROP TABLE [dbo].[StockReceiptItems]
GO

CREATE TABLE [dbo].[StockReceiptItems] (
  [receipt_item_id] int  IDENTITY(1,1) NOT NULL,
  [receipt_id] int  NOT NULL,
  [material_id] int  NULL,
  [material_name_other] nvarchar(300) COLLATE Vietnamese_CI_AS  NULL,
  [qty_ordered] decimal(18,4)  NOT NULL,
  [qty_received] decimal(18,4)  NOT NULL,
  [qty_passed] decimal(18,4)  NOT NULL,
  [qty_failed] decimal(18,4)  NOT NULL,
  [photo_paths] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL
)
GO

ALTER TABLE [dbo].[StockReceiptItems] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for StockReceipts
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[StockReceipts]') AND type IN ('U'))
	DROP TABLE [dbo].[StockReceipts]
GO

CREATE TABLE [dbo].[StockReceipts] (
  [receipt_id] int  IDENTITY(1,1) NOT NULL,
  [receipt_code] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [ipo_id] int  NOT NULL,
  [warehouse_keeper_id] int  NOT NULL,
  [received_at] datetime2(7) DEFAULT getdate() NOT NULL,
  [delivery_note_ref] nvarchar(100) COLLATE Vietnamese_CI_AS  NULL,
  [note] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL
)
GO

ALTER TABLE [dbo].[StockReceipts] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for SupplierContractPrices
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[SupplierContractPrices]') AND type IN ('U'))
	DROP TABLE [dbo].[SupplierContractPrices]
GO

CREATE TABLE [dbo].[SupplierContractPrices] (
  [contract_price_id] int  IDENTITY(1,1) NOT NULL,
  [supplier_id] int  NOT NULL,
  [material_id] int  NOT NULL,
  [contract_unit_price] decimal(18,2)  NOT NULL,
  [valid_from] datetime2(7)  NOT NULL,
  [valid_to] datetime2(7)  NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[SupplierContractPrices] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for SupplierEvaluationCriteria
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[SupplierEvaluationCriteria]') AND type IN ('U'))
	DROP TABLE [dbo].[SupplierEvaluationCriteria]
GO

CREATE TABLE [dbo].[SupplierEvaluationCriteria] (
  [criteria_id] int  IDENTITY(1,1) NOT NULL,
  [evaluation_id] int  NOT NULL,
  [criteria_code] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [criteria_name] nvarchar(150) COLLATE Vietnamese_CI_AS  NOT NULL,
  [raw_score] decimal(5,2)  NOT NULL,
  [weight] decimal(5,4)  NOT NULL,
  [weighted_score] decimal(7,4)  NOT NULL,
  [data_source_json] nvarchar(max) COLLATE Vietnamese_CI_AS  NULL,
  [notes] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL
)
GO

ALTER TABLE [dbo].[SupplierEvaluationCriteria] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for SupplierEvaluations
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[SupplierEvaluations]') AND type IN ('U'))
	DROP TABLE [dbo].[SupplierEvaluations]
GO

CREATE TABLE [dbo].[SupplierEvaluations] (
  [evaluation_id] int  IDENTITY(1,1) NOT NULL,
  [supplier_id] int  NOT NULL,
  [period_type] nvarchar(20) COLLATE Vietnamese_CI_AS  NOT NULL,
  [period_value] nvarchar(20) COLLATE Vietnamese_CI_AS  NOT NULL,
  [period_start_date] datetime2(7)  NOT NULL,
  [period_end_date] datetime2(7)  NOT NULL,
  [total_score] decimal(5,2)  NOT NULL,
  [rank] nvarchar(20) COLLATE Vietnamese_CI_AS  NOT NULL,
  [subjective_comment] nvarchar(1000) COLLATE Vietnamese_CI_AS  NULL,
  [is_finalized] bit DEFAULT 0 NOT NULL,
  [evaluator_user_id] int  NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL,
  [finalized_at] datetime2(7)  NULL
)
GO

ALTER TABLE [dbo].[SupplierEvaluations] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Suppliers
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Suppliers]') AND type IN ('U'))
	DROP TABLE [dbo].[Suppliers]
GO

CREATE TABLE [dbo].[Suppliers] (
  [supplier_id] int  IDENTITY(1,1) NOT NULL,
  [supplier_code] nvarchar(30) COLLATE Vietnamese_CI_AS  NOT NULL,
  [supplier_name] nvarchar(250) COLLATE Vietnamese_CI_AS  NOT NULL,
  [tax_code] nvarchar(20) COLLATE Vietnamese_CI_AS  NULL,
  [contact_name] nvarchar(100) COLLATE Vietnamese_CI_AS  NULL,
  [contact_email] nvarchar(100) COLLATE Vietnamese_CI_AS  NOT NULL,
  [contact_phone] nvarchar(20) COLLATE Vietnamese_CI_AS  NULL,
  [address] nvarchar(500) COLLATE Vietnamese_CI_AS  NULL,
  [rating_score] decimal(5,2) DEFAULT 5.00 NOT NULL,
  [is_active] bit DEFAULT 1 NOT NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[Suppliers] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for SystemConfigs
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[SystemConfigs]') AND type IN ('U'))
	DROP TABLE [dbo].[SystemConfigs]
GO

CREATE TABLE [dbo].[SystemConfigs] (
  [config_id] int  IDENTITY(1,1) NOT NULL,
  [config_key] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [config_value_json] nvarchar(max) COLLATE Vietnamese_CI_AS  NOT NULL,
  [description] nvarchar(300) COLLATE Vietnamese_CI_AS  NULL,
  [updated_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[SystemConfigs] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for token_blacklist_blacklistedtoken
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[token_blacklist_blacklistedtoken]') AND type IN ('U'))
	DROP TABLE [dbo].[token_blacklist_blacklistedtoken]
GO

CREATE TABLE [dbo].[token_blacklist_blacklistedtoken] (
  [id] bigint  IDENTITY(1,1) NOT NULL,
  [blacklisted_at] datetimeoffset(7)  NOT NULL,
  [token_id] bigint  NOT NULL
)
GO

ALTER TABLE [dbo].[token_blacklist_blacklistedtoken] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for token_blacklist_outstandingtoken
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[token_blacklist_outstandingtoken]') AND type IN ('U'))
	DROP TABLE [dbo].[token_blacklist_outstandingtoken]
GO

CREATE TABLE [dbo].[token_blacklist_outstandingtoken] (
  [id] bigint  IDENTITY(1,1) NOT NULL,
  [token] nvarchar(max) COLLATE Vietnamese_CI_AS  NOT NULL,
  [created_at] datetimeoffset(7)  NULL,
  [expires_at] datetimeoffset(7)  NOT NULL,
  [user_id] int  NULL,
  [jti] nvarchar(255) COLLATE Vietnamese_CI_AS  NOT NULL
)
GO

ALTER TABLE [dbo].[token_blacklist_outstandingtoken] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Table structure for Users
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type IN ('U'))
	DROP TABLE [dbo].[Users]
GO

CREATE TABLE [dbo].[Users] (
  [user_id] int  IDENTITY(1,1) NOT NULL,
  [username] nvarchar(50) COLLATE Vietnamese_CI_AS  NOT NULL,
  [password] varchar(255) COLLATE Vietnamese_CI_AS  NOT NULL,
  [full_name] nvarchar(150) COLLATE Vietnamese_CI_AS  NOT NULL,
  [email] nvarchar(100) COLLATE Vietnamese_CI_AS  NOT NULL,
  [phone] nvarchar(20) COLLATE Vietnamese_CI_AS  NULL,
  [branch_id] int  NULL,
  [dept_id] int  NULL,
  [role_id] int  NULL,
  [is_active] bit DEFAULT 1 NOT NULL,
  [is_superuser] bit DEFAULT 0 NOT NULL,
  [is_staff] bit DEFAULT 0 NOT NULL,
  [last_login] datetime2(7)  NULL,
  [login_fail_count] int DEFAULT 0 NOT NULL,
  [locked_until] datetime2(7)  NULL,
  [created_at] datetime2(7) DEFAULT getdate() NOT NULL
)
GO

ALTER TABLE [dbo].[Users] SET (LOCK_ESCALATION = TABLE)
GO


-- ----------------------------
-- Auto increment value for ApprovalWorkflows
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[ApprovalWorkflows]', RESEED, 1)
GO


-- ----------------------------
-- Checks structure for table ApprovalWorkflows
-- ----------------------------
ALTER TABLE [dbo].[ApprovalWorkflows] ADD CONSTRAINT [CK_ApprovalWorkflows_Amount] CHECK ([max_amount] IS NULL OR [max_amount]>=[min_amount])
GO


-- ----------------------------
-- Primary Key structure for table ApprovalWorkflows
-- ----------------------------
ALTER TABLE [dbo].[ApprovalWorkflows] ADD CONSTRAINT [PK__Approval__64A76B70F4572CDC] PRIMARY KEY CLUSTERED ([workflow_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for ApprovalWorkflowSteps
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[ApprovalWorkflowSteps]', RESEED, 1)
GO


-- ----------------------------
-- Primary Key structure for table ApprovalWorkflowSteps
-- ----------------------------
ALTER TABLE [dbo].[ApprovalWorkflowSteps] ADD CONSTRAINT [PK__Approval__B2E1DE815A826F89] PRIMARY KEY CLUSTERED ([step_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for AuditLogs
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[AuditLogs]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table AuditLogs
-- ----------------------------
CREATE NONCLUSTERED INDEX [IX_AuditLogs_performance]
ON [dbo].[AuditLogs] (
  [object_type] ASC,
  [object_id] ASC,
  [created_at] ASC
)
GO


-- ----------------------------
-- Triggers structure for table AuditLogs
-- ----------------------------
CREATE TRIGGER [dbo].[TR_AuditLogs_PreventModify]
ON [dbo].[AuditLogs]
WITH EXECUTE AS CALLER
FOR UPDATE, DELETE
AS
BEGIN
    RAISERROR ('AuditLogs là bảng bảo vệ kiểm toán — không cho phép UPDATE hoặc DELETE.', 16, 1);
    ROLLBACK TRANSACTION;
END;
GO


-- ----------------------------
-- Primary Key structure for table AuditLogs
-- ----------------------------
ALTER TABLE [dbo].[AuditLogs] ADD CONSTRAINT [PK__AuditLog__5AF33E33FAD89C28] PRIMARY KEY CLUSTERED ([audit_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for auth_group
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[auth_group]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table auth_group
-- ----------------------------
ALTER TABLE [dbo].[auth_group] ADD CONSTRAINT [auth_group_name_a6ea08ec_uniq] UNIQUE NONCLUSTERED ([name] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table auth_group
-- ----------------------------
ALTER TABLE [dbo].[auth_group] ADD CONSTRAINT [PK__auth_gro__3213E83F98E11538] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for auth_group_permissions
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[auth_group_permissions]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table auth_group_permissions
-- ----------------------------
CREATE NONCLUSTERED INDEX [auth_group_permissions_permission_id_84c5c92e]
ON [dbo].[auth_group_permissions] (
  [permission_id] ASC
)
GO

CREATE NONCLUSTERED INDEX [auth_group_permissions_group_id_b120cbf9]
ON [dbo].[auth_group_permissions] (
  [group_id] ASC
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [auth_group_permissions_group_id_permission_id_0cd325b0_uniq]
ON [dbo].[auth_group_permissions] (
  [group_id] ASC,
  [permission_id] ASC
)
WHERE ([group_id] IS NOT NULL AND [permission_id] IS NOT NULL)
GO


-- ----------------------------
-- Primary Key structure for table auth_group_permissions
-- ----------------------------
ALTER TABLE [dbo].[auth_group_permissions] ADD CONSTRAINT [PK__auth_gro__3213E83FD5A32759] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for auth_permission
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[auth_permission]', RESEED, 220)
GO


-- ----------------------------
-- Indexes structure for table auth_permission
-- ----------------------------
CREATE UNIQUE NONCLUSTERED INDEX [auth_permission_content_type_id_codename_01ab375a_uniq]
ON [dbo].[auth_permission] (
  [content_type_id] ASC,
  [codename] ASC
)
WHERE ([content_type_id] IS NOT NULL AND [codename] IS NOT NULL)
GO

CREATE NONCLUSTERED INDEX [auth_permission_content_type_id_2f476e4b]
ON [dbo].[auth_permission] (
  [content_type_id] ASC
)
GO


-- ----------------------------
-- Primary Key structure for table auth_permission
-- ----------------------------
ALTER TABLE [dbo].[auth_permission] ADD CONSTRAINT [PK__auth_per__3213E83F879D5DC9] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Branches
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Branches]', RESEED, 5)
GO


-- ----------------------------
-- Uniques structure for table Branches
-- ----------------------------
ALTER TABLE [dbo].[Branches] ADD CONSTRAINT [UQ_Branches_Code] UNIQUE NONCLUSTERED ([branch_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table Branches
-- ----------------------------
ALTER TABLE [dbo].[Branches] ADD CONSTRAINT [PK__Branches__E55E37DED691B733] PRIMARY KEY CLUSTERED ([branch_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table CartPRItems
-- ----------------------------
ALTER TABLE [dbo].[CartPRItems] ADD CONSTRAINT [CK_CartPRItems_Qty] CHECK ([qty_in_cart]>(0))
GO


-- ----------------------------
-- Primary Key structure for table CartPRItems
-- ----------------------------
ALTER TABLE [dbo].[CartPRItems] ADD CONSTRAINT [PK_CartPRItems] PRIMARY KEY CLUSTERED ([cart_id], [pr_item_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Carts
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Carts]', RESEED, 1)
GO


-- ----------------------------
-- Primary Key structure for table Carts
-- ----------------------------
ALTER TABLE [dbo].[Carts] ADD CONSTRAINT [PK__Carts__2EF52A278EBED483] PRIMARY KEY CLUSTERED ([cart_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for CreditNotes
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[CreditNotes]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table CreditNotes
-- ----------------------------
CREATE NONCLUSTERED INDEX [IX_CreditNotes_SupplierStatus]
ON [dbo].[CreditNotes] (
  [supplier_id] ASC,
  [applied_status] ASC,
  [credit_date] ASC
)
GO


-- ----------------------------
-- Uniques structure for table CreditNotes
-- ----------------------------
ALTER TABLE [dbo].[CreditNotes] ADD CONSTRAINT [UQ_CreditNotes_Code] UNIQUE NONCLUSTERED ([credit_note_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table CreditNotes
-- ----------------------------
ALTER TABLE [dbo].[CreditNotes] ADD CONSTRAINT [CK_CreditNotes_Amounts] CHECK ([credit_total_amount]=([credit_amount_before_tax]+[credit_tax_amount]))
GO

ALTER TABLE [dbo].[CreditNotes] ADD CONSTRAINT [CK_CreditNotes_AmountPositive] CHECK ([credit_total_amount]>(0))
GO

ALTER TABLE [dbo].[CreditNotes] ADD CONSTRAINT [CK_CreditNotes_Status] CHECK ([applied_status]='REFUNDED' OR [applied_status]='APPLIED' OR [applied_status]='PENDING')
GO


-- ----------------------------
-- Primary Key structure for table CreditNotes
-- ----------------------------
ALTER TABLE [dbo].[CreditNotes] ADD CONSTRAINT [PK__CreditNo__66B911E5F4F98456] PRIMARY KEY CLUSTERED ([credit_note_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for DebitNotes
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[DebitNotes]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table DebitNotes
-- ----------------------------
CREATE NONCLUSTERED INDEX [IX_DebitNotes_SupplierStatus]
ON [dbo].[DebitNotes] (
  [supplier_id] ASC,
  [applied_status] ASC,
  [debit_date] ASC
)
GO


-- ----------------------------
-- Uniques structure for table DebitNotes
-- ----------------------------
ALTER TABLE [dbo].[DebitNotes] ADD CONSTRAINT [UQ_DebitNotes_Code] UNIQUE NONCLUSTERED ([debit_note_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table DebitNotes
-- ----------------------------
ALTER TABLE [dbo].[DebitNotes] ADD CONSTRAINT [CK_DebitNotes_AmountPositive] CHECK ([debit_amount]>(0))
GO

ALTER TABLE [dbo].[DebitNotes] ADD CONSTRAINT [CK_DebitNotes_Status] CHECK ([applied_status]='APPLIED' OR [applied_status]='PENDING')
GO


-- ----------------------------
-- Primary Key structure for table DebitNotes
-- ----------------------------
ALTER TABLE [dbo].[DebitNotes] ADD CONSTRAINT [PK__DebitNot__F32546EA76DB9CD1] PRIMARY KEY CLUSTERED ([debit_note_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Departments
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Departments]', RESEED, 16)
GO


-- ----------------------------
-- Uniques structure for table Departments
-- ----------------------------
ALTER TABLE [dbo].[Departments] ADD CONSTRAINT [UQ_Departments_Code] UNIQUE NONCLUSTERED ([dept_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table Departments
-- ----------------------------
ALTER TABLE [dbo].[Departments] ADD CONSTRAINT [PK__Departme__DCA65974FB84A8C3] PRIMARY KEY CLUSTERED ([dept_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for django_admin_log
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[django_admin_log]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table django_admin_log
-- ----------------------------
CREATE NONCLUSTERED INDEX [django_admin_log_content_type_id_c4bce8eb]
ON [dbo].[django_admin_log] (
  [content_type_id] ASC
)
GO

CREATE NONCLUSTERED INDEX [django_admin_log_user_id_c564eba6]
ON [dbo].[django_admin_log] (
  [user_id] ASC
)
GO


-- ----------------------------
-- Checks structure for table django_admin_log
-- ----------------------------
ALTER TABLE [dbo].[django_admin_log] ADD CONSTRAINT [django_admin_log_action_flag_a8637d59_check] CHECK ([action_flag]>=(0))
GO


-- ----------------------------
-- Primary Key structure for table django_admin_log
-- ----------------------------
ALTER TABLE [dbo].[django_admin_log] ADD CONSTRAINT [PK__django_a__3213E83F60C1A01F] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for django_celery_results_chordcounter
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[django_celery_results_chordcounter]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table django_celery_results_chordcounter
-- ----------------------------
ALTER TABLE [dbo].[django_celery_results_chordcounter] ADD CONSTRAINT [UQ__django_c__D57795A1C1BDF190] UNIQUE NONCLUSTERED ([group_id] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table django_celery_results_chordcounter
-- ----------------------------
ALTER TABLE [dbo].[django_celery_results_chordcounter] ADD CONSTRAINT [django_celery_results_chordcounter_count_4605448d_check] CHECK ([count]>=(0))
GO


-- ----------------------------
-- Primary Key structure for table django_celery_results_chordcounter
-- ----------------------------
ALTER TABLE [dbo].[django_celery_results_chordcounter] ADD CONSTRAINT [PK__django_c__3213E83F24D82D80] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for django_celery_results_groupresult
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[django_celery_results_groupresult]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table django_celery_results_groupresult
-- ----------------------------
CREATE NONCLUSTERED INDEX [django_cele_date_cr_bd6c1d_idx]
ON [dbo].[django_celery_results_groupresult] (
  [date_created] ASC
)
GO

CREATE NONCLUSTERED INDEX [django_cele_date_do_caae0e_idx]
ON [dbo].[django_celery_results_groupresult] (
  [date_done] ASC
)
GO


-- ----------------------------
-- Uniques structure for table django_celery_results_groupresult
-- ----------------------------
ALTER TABLE [dbo].[django_celery_results_groupresult] ADD CONSTRAINT [UQ__django_c__D57795A1F482BAAE] UNIQUE NONCLUSTERED ([group_id] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table django_celery_results_groupresult
-- ----------------------------
ALTER TABLE [dbo].[django_celery_results_groupresult] ADD CONSTRAINT [PK__django_c__3213E83FBC878726] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for django_celery_results_taskresult
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[django_celery_results_taskresult]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table django_celery_results_taskresult
-- ----------------------------
CREATE NONCLUSTERED INDEX [django_cele_task_na_08aec9_idx]
ON [dbo].[django_celery_results_taskresult] (
  [task_name] ASC
)
GO

CREATE NONCLUSTERED INDEX [django_cele_status_9b6201_idx]
ON [dbo].[django_celery_results_taskresult] (
  [status] ASC
)
GO

CREATE NONCLUSTERED INDEX [django_cele_worker_d54dd8_idx]
ON [dbo].[django_celery_results_taskresult] (
  [worker] ASC
)
GO

CREATE NONCLUSTERED INDEX [django_cele_date_cr_f04a50_idx]
ON [dbo].[django_celery_results_taskresult] (
  [date_created] ASC
)
GO

CREATE NONCLUSTERED INDEX [django_cele_date_do_f59aad_idx]
ON [dbo].[django_celery_results_taskresult] (
  [date_done] ASC
)
GO


-- ----------------------------
-- Uniques structure for table django_celery_results_taskresult
-- ----------------------------
ALTER TABLE [dbo].[django_celery_results_taskresult] ADD CONSTRAINT [UQ__django_c__0492148C4AB491A7] UNIQUE NONCLUSTERED ([task_id] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table django_celery_results_taskresult
-- ----------------------------
ALTER TABLE [dbo].[django_celery_results_taskresult] ADD CONSTRAINT [PK__django_c__3213E83FED8CA77B] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for django_content_type
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[django_content_type]', RESEED, 55)
GO


-- ----------------------------
-- Indexes structure for table django_content_type
-- ----------------------------
CREATE UNIQUE NONCLUSTERED INDEX [django_content_type_app_label_model_76bd3d3b_uniq]
ON [dbo].[django_content_type] (
  [app_label] ASC,
  [model] ASC
)
WHERE ([app_label] IS NOT NULL AND [model] IS NOT NULL)
GO


-- ----------------------------
-- Primary Key structure for table django_content_type
-- ----------------------------
ALTER TABLE [dbo].[django_content_type] ADD CONSTRAINT [PK__django_c__3213E83F5DB56D30] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for django_migrations
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[django_migrations]', RESEED, 40)
GO


-- ----------------------------
-- Primary Key structure for table django_migrations
-- ----------------------------
ALTER TABLE [dbo].[django_migrations] ADD CONSTRAINT [PK__django_m__3213E83FF76496F3] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Indexes structure for table django_session
-- ----------------------------
CREATE NONCLUSTERED INDEX [django_session_expire_date_a5c62663]
ON [dbo].[django_session] (
  [expire_date] ASC
)
GO


-- ----------------------------
-- Primary Key structure for table django_session
-- ----------------------------
ALTER TABLE [dbo].[django_session] ADD CONSTRAINT [PK__django_s__B3BA0F1FDEE39D11] PRIMARY KEY CLUSTERED ([session_key])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for DocumentApprovalProgress
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[DocumentApprovalProgress]', RESEED, 1)
GO


-- ----------------------------
-- Checks structure for table DocumentApprovalProgress
-- ----------------------------
ALTER TABLE [dbo].[DocumentApprovalProgress] ADD CONSTRAINT [CK_DocApproval_Status] CHECK ([approval_status]='REJECTED' OR [approval_status]='APPROVED' OR [approval_status]='PENDING')
GO


-- ----------------------------
-- Primary Key structure for table DocumentApprovalProgress
-- ----------------------------
ALTER TABLE [dbo].[DocumentApprovalProgress] ADD CONSTRAINT [PK__Document__49B3D8C18CD6632B] PRIMARY KEY CLUSTERED ([progress_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for EmailTemplates
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[EmailTemplates]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table EmailTemplates
-- ----------------------------
CREATE NONCLUSTERED INDEX [IX_EmailTemplates_Lookup]
ON [dbo].[EmailTemplates] (
  [template_code] ASC,
  [language] ASC,
  [channel] ASC,
  [is_active] ASC
)
GO


-- ----------------------------
-- Triggers structure for table EmailTemplates
-- ----------------------------
CREATE TRIGGER [dbo].[TR_EmailTemplates_PreventSystemDelete]
ON [dbo].[EmailTemplates]
WITH EXECUTE AS CALLER
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


-- ----------------------------
-- Uniques structure for table EmailTemplates
-- ----------------------------
ALTER TABLE [dbo].[EmailTemplates] ADD CONSTRAINT [UQ_EmailTemplates_CodeLang] UNIQUE NONCLUSTERED ([template_code] ASC, [language] ASC, [channel] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table EmailTemplates
-- ----------------------------
ALTER TABLE [dbo].[EmailTemplates] ADD CONSTRAINT [CK_EmailTemplates_Channel] CHECK ([channel]='SMS' OR [channel]='IN_APP' OR [channel]='EMAIL')
GO

ALTER TABLE [dbo].[EmailTemplates] ADD CONSTRAINT [CK_EmailTemplates_BodyRequired] CHECK ([body_html] IS NOT NULL OR [body_plain_text] IS NOT NULL)
GO


-- ----------------------------
-- Primary Key structure for table EmailTemplates
-- ----------------------------
ALTER TABLE [dbo].[EmailTemplates] ADD CONSTRAINT [PK__EmailTem__BE44E079F3BD6EC3] PRIMARY KEY CLUSTERED ([template_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Inventory
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Inventory]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table Inventory
-- ----------------------------
ALTER TABLE [dbo].[Inventory] ADD CONSTRAINT [UQ_Inventory_BranchMaterial] UNIQUE NONCLUSTERED ([branch_id] ASC, [material_id] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table Inventory
-- ----------------------------
ALTER TABLE [dbo].[Inventory] ADD CONSTRAINT [CK_Inventory_Min] CHECK ([qty_on_hand]>=(0) AND [qty_available]>=(0) AND [qty_quarantine]>=(0))
GO


-- ----------------------------
-- Primary Key structure for table Inventory
-- ----------------------------
ALTER TABLE [dbo].[Inventory] ADD CONSTRAINT [PK__Inventor__B59ACC494F536C25] PRIMARY KEY CLUSTERED ([inventory_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for InvoiceMatchingResults
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[InvoiceMatchingResults]', RESEED, 1)
GO


-- ----------------------------
-- Primary Key structure for table InvoiceMatchingResults
-- ----------------------------
ALTER TABLE [dbo].[InvoiceMatchingResults] ADD CONSTRAINT [PK__InvoiceM__332F9C1ABE93C5D2] PRIMARY KEY CLUSTERED ([matching_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Invoices
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Invoices]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table Invoices
-- ----------------------------
CREATE NONCLUSTERED INDEX [IX_InvoiceMatching_Run]
ON [dbo].[Invoices] (
  [ipo_id] ASC,
  [matching_status] ASC
)
GO


-- ----------------------------
-- Uniques structure for table Invoices
-- ----------------------------
ALTER TABLE [dbo].[Invoices] ADD CONSTRAINT [UQ_Invoices_NumberSupplier] UNIQUE NONCLUSTERED ([invoice_number] ASC, [supplier_id] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table Invoices
-- ----------------------------
ALTER TABLE [dbo].[Invoices] ADD CONSTRAINT [CK_Invoices_Amounts] CHECK ([total_amount]=([amount_before_tax]+[tax_amount]))
GO

ALTER TABLE [dbo].[Invoices] ADD CONSTRAINT [CK_Invoices_MatchStatus] CHECK ([matching_status]='MISMATCHED' OR [matching_status]='MATCHED' OR [matching_status]='PENDING')
GO


-- ----------------------------
-- Primary Key structure for table Invoices
-- ----------------------------
ALTER TABLE [dbo].[Invoices] ADD CONSTRAINT [PK__Invoices__F58DFD4982CA63B6] PRIMARY KEY CLUSTERED ([invoice_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for IPOItems
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[IPOItems]', RESEED, 1)
GO


-- ----------------------------
-- Checks structure for table IPOItems
-- ----------------------------
ALTER TABLE [dbo].[IPOItems] ADD CONSTRAINT [CK_IPOItems_Values] CHECK ([qty_final]>(0) AND [unit_price_final]>=(0))
GO


-- ----------------------------
-- Primary Key structure for table IPOItems
-- ----------------------------
ALTER TABLE [dbo].[IPOItems] ADD CONSTRAINT [PK__IPOItems__3810E00CE6E39234] PRIMARY KEY CLUSTERED ([ipo_item_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for IPOs
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[IPOs]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table IPOs
-- ----------------------------
CREATE NONCLUSTERED INDEX [IX_IPO_LatestVersion]
ON [dbo].[IPOs] (
  [ipo_code] ASC,
  [is_latest] ASC,
  [ipo_status] ASC
)
GO


-- ----------------------------
-- Checks structure for table IPOs
-- ----------------------------
ALTER TABLE [dbo].[IPOs] ADD CONSTRAINT [CK_IPOs_Status] CHECK ([ipo_status]='REJECTED' OR [ipo_status]='APPROVED' OR [ipo_status]='PENDING' OR [ipo_status]='DRAFT')
GO


-- ----------------------------
-- Primary Key structure for table IPOs
-- ----------------------------
ALTER TABLE [dbo].[IPOs] ADD CONSTRAINT [PK__IPOs__A1CA100838D83685] PRIMARY KEY CLUSTERED ([ipo_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for MaterialCategories
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[MaterialCategories]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table MaterialCategories
-- ----------------------------
ALTER TABLE [dbo].[MaterialCategories] ADD CONSTRAINT [UQ_MaterialCategories_Code] UNIQUE NONCLUSTERED ([category_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table MaterialCategories
-- ----------------------------
ALTER TABLE [dbo].[MaterialCategories] ADD CONSTRAINT [PK__Material__D54EE9B4DBC806AC] PRIMARY KEY CLUSTERED ([category_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Materials
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Materials]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table Materials
-- ----------------------------
ALTER TABLE [dbo].[Materials] ADD CONSTRAINT [UQ_Materials_Code] UNIQUE NONCLUSTERED ([material_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table Materials
-- ----------------------------
ALTER TABLE [dbo].[Materials] ADD CONSTRAINT [PK__Material__6BFE1D28A7E25B21] PRIMARY KEY CLUSTERED ([material_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Notifications
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Notifications]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table Notifications
-- ----------------------------
CREATE NONCLUSTERED INDEX [IX_Notifications_Unread]
ON [dbo].[Notifications] (
  [recipient_user_id] ASC,
  [is_read] ASC
)
GO


-- ----------------------------
-- Primary Key structure for table Notifications
-- ----------------------------
ALTER TABLE [dbo].[Notifications] ADD CONSTRAINT [PK__Notifica__E059842F1D4A8635] PRIMARY KEY CLUSTERED ([notification_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table OrderItemPRLinks
-- ----------------------------
ALTER TABLE [dbo].[OrderItemPRLinks] ADD CONSTRAINT [PK_OrderItemPRLinks] PRIMARY KEY CLUSTERED ([order_item_id], [pr_item_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for OrderItems
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[OrderItems]', RESEED, 1)
GO


-- ----------------------------
-- Checks structure for table OrderItems
-- ----------------------------
ALTER TABLE [dbo].[OrderItems] ADD CONSTRAINT [CK_OrderItems_Qty] CHECK ([qty_total_ordered]>(0))
GO

ALTER TABLE [dbo].[OrderItems] ADD CONSTRAINT [CK_OrderItems_MaterialCheck] CHECK ([material_id] IS NOT NULL AND [material_name_other] IS NULL OR [material_id] IS NULL AND [material_name_other] IS NOT NULL)
GO


-- ----------------------------
-- Primary Key structure for table OrderItems
-- ----------------------------
ALTER TABLE [dbo].[OrderItems] ADD CONSTRAINT [PK__OrderIte__3764B6BC0927ABC6] PRIMARY KEY CLUSTERED ([order_item_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Orders
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Orders]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table Orders
-- ----------------------------
ALTER TABLE [dbo].[Orders] ADD CONSTRAINT [UQ_Orders_Code] UNIQUE NONCLUSTERED ([order_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table Orders
-- ----------------------------
ALTER TABLE [dbo].[Orders] ADD CONSTRAINT [CK_Orders_Status] CHECK ([order_status]='COMPLETED' OR [order_status]='QUOTING' OR [order_status]='DRAFT')
GO


-- ----------------------------
-- Primary Key structure for table Orders
-- ----------------------------
ALTER TABLE [dbo].[Orders] ADD CONSTRAINT [PK__Orders__4659622998DBB16E] PRIMARY KEY CLUSTERED ([order_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table OrderSuppliers
-- ----------------------------
ALTER TABLE [dbo].[OrderSuppliers] ADD CONSTRAINT [PK_OrderSuppliers] PRIMARY KEY CLUSTERED ([order_id], [supplier_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for PaymentRequests
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[PaymentRequests]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table PaymentRequests
-- ----------------------------
ALTER TABLE [dbo].[PaymentRequests] ADD CONSTRAINT [UQ_PaymentRequests_Code] UNIQUE NONCLUSTERED ([payment_req_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table PaymentRequests
-- ----------------------------
ALTER TABLE [dbo].[PaymentRequests] ADD CONSTRAINT [CK_PaymentReq_Status] CHECK ([req_status]='REJECTED' OR [req_status]='PAID' OR [req_status]='APPROVED' OR [req_status]='PENDING')
GO


-- ----------------------------
-- Primary Key structure for table PaymentRequests
-- ----------------------------
ALTER TABLE [dbo].[PaymentRequests] ADD CONSTRAINT [PK__PaymentR__BB5ACE8229A29F2A] PRIMARY KEY CLUSTERED ([payment_req_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Permissions
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Permissions]', RESEED, 44)
GO


-- ----------------------------
-- Uniques structure for table Permissions
-- ----------------------------
ALTER TABLE [dbo].[Permissions] ADD CONSTRAINT [UQ_Permissions_Code] UNIQUE NONCLUSTERED ([permission_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table Permissions
-- ----------------------------
ALTER TABLE [dbo].[Permissions] ADD CONSTRAINT [PK__Permissi__E5331AFAA3098158] PRIMARY KEY CLUSTERED ([permission_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for PRItems
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[PRItems]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table PRItems
-- ----------------------------
CREATE NONCLUSTERED INDEX [IX_PRItems_Lookup]
ON [dbo].[PRItems] (
  [pr_id] ASC,
  [item_status] ASC
)
GO


-- ----------------------------
-- Checks structure for table PRItems
-- ----------------------------
ALTER TABLE [dbo].[PRItems] ADD CONSTRAINT [CK_PRItems_QtyPositive] CHECK ([qty_requested]>(0))
GO

ALTER TABLE [dbo].[PRItems] ADD CONSTRAINT [CK_PRItems_QtyOrderedSanity] CHECK ([qty_ordered]<=[qty_requested])
GO

ALTER TABLE [dbo].[PRItems] ADD CONSTRAINT [CK_PRItems_QtyReceivedSanity] CHECK ([qty_received]<=[qty_ordered])
GO

ALTER TABLE [dbo].[PRItems] ADD CONSTRAINT [CK_PRItems_MaterialCheck] CHECK ([material_id] IS NOT NULL AND [material_name_other] IS NULL OR [material_id] IS NULL AND [material_name_other] IS NOT NULL)
GO


-- ----------------------------
-- Primary Key structure for table PRItems
-- ----------------------------
ALTER TABLE [dbo].[PRItems] ADD CONSTRAINT [PK__PRItems__B62BD67B94166DF7] PRIMARY KEY CLUSTERED ([pr_item_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for PRStatusHistory
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[PRStatusHistory]', RESEED, 1)
GO


-- ----------------------------
-- Primary Key structure for table PRStatusHistory
-- ----------------------------
ALTER TABLE [dbo].[PRStatusHistory] ADD CONSTRAINT [PK__PRStatus__096AA2E91B320351] PRIMARY KEY CLUSTERED ([history_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for PurchaseRequisitions
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[PurchaseRequisitions]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table PurchaseRequisitions
-- ----------------------------
ALTER TABLE [dbo].[PurchaseRequisitions] ADD CONSTRAINT [UQ_PR_Code] UNIQUE NONCLUSTERED ([pr_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table PurchaseRequisitions
-- ----------------------------
ALTER TABLE [dbo].[PurchaseRequisitions] ADD CONSTRAINT [CK_PR_Priority] CHECK ([priority_level]='URGENT' OR [priority_level]='NORMAL')
GO

ALTER TABLE [dbo].[PurchaseRequisitions] ADD CONSTRAINT [CK_PR_Status] CHECK ([pr_status]='CANCELLED' OR [pr_status]='REJECTED' OR [pr_status]='APPROVED' OR [pr_status]='PENDING' OR [pr_status]='DRAFT')
GO

ALTER TABLE [dbo].[PurchaseRequisitions] ADD CONSTRAINT [CK_PR_UrgentFields] CHECK ([priority_level]<>'URGENT' OR [urgent_reason] IS NOT NULL AND [urgency_impact] IS NOT NULL)
GO


-- ----------------------------
-- Primary Key structure for table PurchaseRequisitions
-- ----------------------------
ALTER TABLE [dbo].[PurchaseRequisitions] ADD CONSTRAINT [PK__Purchase__47B09F8EFD394879] PRIMARY KEY CLUSTERED ([pr_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for QuotationItems
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[QuotationItems]', RESEED, 1)
GO


-- ----------------------------
-- Checks structure for table QuotationItems
-- ----------------------------
ALTER TABLE [dbo].[QuotationItems] ADD CONSTRAINT [CK_QuotationItems_Price] CHECK ([quoted_unit_price]>=(0))
GO


-- ----------------------------
-- Primary Key structure for table QuotationItems
-- ----------------------------
ALTER TABLE [dbo].[QuotationItems] ADD CONSTRAINT [PK__Quotatio__649D66052DC91617] PRIMARY KEY CLUSTERED ([q_item_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for QuotationRequests
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[QuotationRequests]', RESEED, 1)
GO


-- ----------------------------
-- Primary Key structure for table QuotationRequests
-- ----------------------------
ALTER TABLE [dbo].[QuotationRequests] ADD CONSTRAINT [PK__Quotatio__AE83733097418AD3] PRIMARY KEY CLUSTERED ([q_request_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Quotations
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Quotations]', RESEED, 1)
GO


-- ----------------------------
-- Primary Key structure for table Quotations
-- ----------------------------
ALTER TABLE [dbo].[Quotations] ADD CONSTRAINT [PK__Quotatio__7841D7DBFDA3BD08] PRIMARY KEY CLUSTERED ([quotation_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for QuotationTokens
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[QuotationTokens]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table QuotationTokens
-- ----------------------------
ALTER TABLE [dbo].[QuotationTokens] ADD CONSTRAINT [UQ_QuotationTokens_Token] UNIQUE NONCLUSTERED ([token] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table QuotationTokens
-- ----------------------------
ALTER TABLE [dbo].[QuotationTokens] ADD CONSTRAINT [PK__Quotatio__CB3C9E17A5C0DE9F] PRIMARY KEY CLUSTERED ([token_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for QuotationVersions
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[QuotationVersions]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table QuotationVersions
-- ----------------------------
CREATE NONCLUSTERED INDEX [IX_QuotationVersions_Current]
ON [dbo].[QuotationVersions] (
  [quotation_id] ASC,
  [is_current] ASC,
  [version_number] ASC
)
GO


-- ----------------------------
-- Uniques structure for table QuotationVersions
-- ----------------------------
ALTER TABLE [dbo].[QuotationVersions] ADD CONSTRAINT [UQ_QuotationVersions_Number] UNIQUE NONCLUSTERED ([quotation_id] ASC, [version_number] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table QuotationVersions
-- ----------------------------
ALTER TABLE [dbo].[QuotationVersions] ADD CONSTRAINT [CK_QuotationVersions_VersionPositive] CHECK ([version_number]>(0))
GO

ALTER TABLE [dbo].[QuotationVersions] ADD CONSTRAINT [CK_QuotationVersions_AmountNonNegative] CHECK ([snapshot_total_amount]>=(0))
GO


-- ----------------------------
-- Primary Key structure for table QuotationVersions
-- ----------------------------
ALTER TABLE [dbo].[QuotationVersions] ADD CONSTRAINT [PK__Quotatio__07A58869EC66687D] PRIMARY KEY CLUSTERED ([version_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for ReturnOrderItems
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[ReturnOrderItems]', RESEED, 1)
GO


-- ----------------------------
-- Checks structure for table ReturnOrderItems
-- ----------------------------
ALTER TABLE [dbo].[ReturnOrderItems] ADD CONSTRAINT [CK_ReturnOrderItems_Qty] CHECK ([qty_returned]>(0))
GO


-- ----------------------------
-- Primary Key structure for table ReturnOrderItems
-- ----------------------------
ALTER TABLE [dbo].[ReturnOrderItems] ADD CONSTRAINT [PK__ReturnOr__3CFDE9F2BAB87EF4] PRIMARY KEY CLUSTERED ([return_item_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for ReturnOrders
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[ReturnOrders]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table ReturnOrders
-- ----------------------------
ALTER TABLE [dbo].[ReturnOrders] ADD CONSTRAINT [UQ_ReturnOrders_Code] UNIQUE NONCLUSTERED ([return_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table ReturnOrders
-- ----------------------------
ALTER TABLE [dbo].[ReturnOrders] ADD CONSTRAINT [CK_ReturnOrders_Status] CHECK ([return_status]='RESOLVED' OR [return_status]='SENT' OR [return_status]='DRAFT')
GO


-- ----------------------------
-- Primary Key structure for table ReturnOrders
-- ----------------------------
ALTER TABLE [dbo].[ReturnOrders] ADD CONSTRAINT [PK__ReturnOr__35C23473263B05FB] PRIMARY KEY CLUSTERED ([return_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table RolePermissions
-- ----------------------------
ALTER TABLE [dbo].[RolePermissions] ADD CONSTRAINT [PK_RolePermissions] PRIMARY KEY CLUSTERED ([role_permission_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Roles
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Roles]', RESEED, 10)
GO


-- ----------------------------
-- Uniques structure for table Roles
-- ----------------------------
ALTER TABLE [dbo].[Roles] ADD CONSTRAINT [UQ_Roles_Code] UNIQUE NONCLUSTERED ([role_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table Roles
-- ----------------------------
ALTER TABLE [dbo].[Roles] ADD CONSTRAINT [PK__Roles__760965CC1DA4A1B4] PRIMARY KEY CLUSTERED ([role_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for StockIssueItems
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[StockIssueItems]', RESEED, 1)
GO


-- ----------------------------
-- Checks structure for table StockIssueItems
-- ----------------------------
ALTER TABLE [dbo].[StockIssueItems] ADD CONSTRAINT [CK_StockIssueItems_Qty] CHECK ([qty_issued]>(0))
GO

ALTER TABLE [dbo].[StockIssueItems] ADD CONSTRAINT [CK_StockIssueItems_Rating] CHECK ([quality_rating] IS NULL OR [quality_rating]>=(1) AND [quality_rating]<=(5))
GO


-- ----------------------------
-- Primary Key structure for table StockIssueItems
-- ----------------------------
ALTER TABLE [dbo].[StockIssueItems] ADD CONSTRAINT [PK__StockIss__CE3803FE8DBFE8F9] PRIMARY KEY CLUSTERED ([issue_item_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for StockIssues
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[StockIssues]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table StockIssues
-- ----------------------------
ALTER TABLE [dbo].[StockIssues] ADD CONSTRAINT [UQ_StockIssues_Code] UNIQUE NONCLUSTERED ([issue_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table StockIssues
-- ----------------------------
ALTER TABLE [dbo].[StockIssues] ADD CONSTRAINT [PK__StockIss__D6185C3960AEC230] PRIMARY KEY CLUSTERED ([issue_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for StockReceiptItems
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[StockReceiptItems]', RESEED, 1)
GO


-- ----------------------------
-- Checks structure for table StockReceiptItems
-- ----------------------------
ALTER TABLE [dbo].[StockReceiptItems] ADD CONSTRAINT [CK_StockReceiptItems_QtyLogic] CHECK ([qty_received]>=(0) AND [qty_passed]>=(0) AND [qty_failed]>=(0) AND [qty_received]=([qty_passed]+[qty_failed]))
GO

ALTER TABLE [dbo].[StockReceiptItems] ADD CONSTRAINT [CK_StockReceiptItems_MaterialCheck] CHECK ([material_id] IS NOT NULL AND [material_name_other] IS NULL OR [material_id] IS NULL AND [material_name_other] IS NOT NULL)
GO

ALTER TABLE [dbo].[StockReceiptItems] ADD CONSTRAINT [CK_StockReceiptItems_PhotoMandatory] CHECK ([qty_failed]=(0) OR [photo_paths] IS NOT NULL)
GO


-- ----------------------------
-- Primary Key structure for table StockReceiptItems
-- ----------------------------
ALTER TABLE [dbo].[StockReceiptItems] ADD CONSTRAINT [PK__StockRec__D1862CE15B48AFF4] PRIMARY KEY CLUSTERED ([receipt_item_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for StockReceipts
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[StockReceipts]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table StockReceipts
-- ----------------------------
ALTER TABLE [dbo].[StockReceipts] ADD CONSTRAINT [UQ_StockReceipts_Code] UNIQUE NONCLUSTERED ([receipt_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table StockReceipts
-- ----------------------------
ALTER TABLE [dbo].[StockReceipts] ADD CONSTRAINT [PK__StockRec__91F52C1FD4599044] PRIMARY KEY CLUSTERED ([receipt_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for SupplierContractPrices
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[SupplierContractPrices]', RESEED, 1)
GO


-- ----------------------------
-- Checks structure for table SupplierContractPrices
-- ----------------------------
ALTER TABLE [dbo].[SupplierContractPrices] ADD CONSTRAINT [CK_ContractPrices_Dates] CHECK ([valid_to]>=[valid_from])
GO


-- ----------------------------
-- Primary Key structure for table SupplierContractPrices
-- ----------------------------
ALTER TABLE [dbo].[SupplierContractPrices] ADD CONSTRAINT [PK__Supplier__56DF25765DA8BDBA] PRIMARY KEY CLUSTERED ([contract_price_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for SupplierEvaluationCriteria
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[SupplierEvaluationCriteria]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table SupplierEvaluationCriteria
-- ----------------------------
ALTER TABLE [dbo].[SupplierEvaluationCriteria] ADD CONSTRAINT [UQ_EvalCriteria_EvalCode] UNIQUE NONCLUSTERED ([evaluation_id] ASC, [criteria_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table SupplierEvaluationCriteria
-- ----------------------------
ALTER TABLE [dbo].[SupplierEvaluationCriteria] ADD CONSTRAINT [CK_EvalCriteria_RawScore] CHECK ([raw_score]>=(0) AND [raw_score]<=(100))
GO

ALTER TABLE [dbo].[SupplierEvaluationCriteria] ADD CONSTRAINT [CK_EvalCriteria_Weight] CHECK ([weight]>=(0) AND [weight]<=(1))
GO


-- ----------------------------
-- Primary Key structure for table SupplierEvaluationCriteria
-- ----------------------------
ALTER TABLE [dbo].[SupplierEvaluationCriteria] ADD CONSTRAINT [PK__Supplier__401F949D1A6F8AC5] PRIMARY KEY CLUSTERED ([criteria_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for SupplierEvaluations
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[SupplierEvaluations]', RESEED, 1)
GO


-- ----------------------------
-- Indexes structure for table SupplierEvaluations
-- ----------------------------
CREATE NONCLUSTERED INDEX [IX_SupplierEvaluations_Period]
ON [dbo].[SupplierEvaluations] (
  [supplier_id] ASC,
  [period_type] ASC,
  [period_value] ASC,
  [is_finalized] ASC
)
GO


-- ----------------------------
-- Uniques structure for table SupplierEvaluations
-- ----------------------------
ALTER TABLE [dbo].[SupplierEvaluations] ADD CONSTRAINT [UQ_SupplierEvaluations_Period] UNIQUE NONCLUSTERED ([supplier_id] ASC, [period_type] ASC, [period_value] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Checks structure for table SupplierEvaluations
-- ----------------------------
ALTER TABLE [dbo].[SupplierEvaluations] ADD CONSTRAINT [CK_SupplierEvaluations_Score] CHECK ([total_score]>=(0) AND [total_score]<=(100))
GO

ALTER TABLE [dbo].[SupplierEvaluations] ADD CONSTRAINT [CK_SupplierEvaluations_Rank] CHECK ([rank]='WARNING' OR [rank]='BRONZE' OR [rank]='SILVER' OR [rank]='GOLD')
GO

ALTER TABLE [dbo].[SupplierEvaluations] ADD CONSTRAINT [CK_SupplierEvaluations_PeriodType] CHECK ([period_type]='YEAR' OR [period_type]='QUARTER' OR [period_type]='MONTH')
GO

ALTER TABLE [dbo].[SupplierEvaluations] ADD CONSTRAINT [CK_SupplierEvaluations_DateRange] CHECK ([period_end_date]>[period_start_date])
GO


-- ----------------------------
-- Primary Key structure for table SupplierEvaluations
-- ----------------------------
ALTER TABLE [dbo].[SupplierEvaluations] ADD CONSTRAINT [PK__Supplier__827C592DD7250AE9] PRIMARY KEY CLUSTERED ([evaluation_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Suppliers
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Suppliers]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table Suppliers
-- ----------------------------
ALTER TABLE [dbo].[Suppliers] ADD CONSTRAINT [UQ_Suppliers_Code] UNIQUE NONCLUSTERED ([supplier_code] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table Suppliers
-- ----------------------------
ALTER TABLE [dbo].[Suppliers] ADD CONSTRAINT [PK__Supplier__6EE594E896AE7683] PRIMARY KEY CLUSTERED ([supplier_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for SystemConfigs
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[SystemConfigs]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table SystemConfigs
-- ----------------------------
ALTER TABLE [dbo].[SystemConfigs] ADD CONSTRAINT [UQ_SystemConfigs_Key] UNIQUE NONCLUSTERED ([config_key] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table SystemConfigs
-- ----------------------------
ALTER TABLE [dbo].[SystemConfigs] ADD CONSTRAINT [PK__SystemCo__4AD1BFF1FED3878C] PRIMARY KEY CLUSTERED ([config_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for token_blacklist_blacklistedtoken
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[token_blacklist_blacklistedtoken]', RESEED, 1)
GO


-- ----------------------------
-- Primary Key structure for table token_blacklist_blacklistedtoken
-- ----------------------------
ALTER TABLE [dbo].[token_blacklist_blacklistedtoken] ADD CONSTRAINT [token_blacklist_blacklistedtoken_id_e1c86975_pk] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for token_blacklist_outstandingtoken
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[token_blacklist_outstandingtoken]', RESEED, 1)
GO


-- ----------------------------
-- Uniques structure for table token_blacklist_outstandingtoken
-- ----------------------------
ALTER TABLE [dbo].[token_blacklist_outstandingtoken] ADD CONSTRAINT [token_blacklist_outstandingtoken_jti_hex_d9bdf6f7_uniq] UNIQUE NONCLUSTERED ([jti] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table token_blacklist_outstandingtoken
-- ----------------------------
ALTER TABLE [dbo].[token_blacklist_outstandingtoken] ADD CONSTRAINT [token_blacklist_outstandingtoken_id_69982597_pk] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Auto increment value for Users
-- ----------------------------
DBCC CHECKIDENT ('[dbo].[Users]', RESEED, 21)
GO


-- ----------------------------
-- Uniques structure for table Users
-- ----------------------------
ALTER TABLE [dbo].[Users] ADD CONSTRAINT [UQ_Users_Email] UNIQUE NONCLUSTERED ([email] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO

ALTER TABLE [dbo].[Users] ADD CONSTRAINT [UQ_Users_Username] UNIQUE NONCLUSTERED ([username] ASC)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Primary Key structure for table Users
-- ----------------------------
ALTER TABLE [dbo].[Users] ADD CONSTRAINT [PK__Users__B9BE370FE4CD0EC2] PRIMARY KEY CLUSTERED ([user_id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)  
ON [PRIMARY]
GO


-- ----------------------------
-- Foreign Keys structure for table ApprovalWorkflows
-- ----------------------------
ALTER TABLE [dbo].[ApprovalWorkflows] ADD CONSTRAINT [FK_ApprovalWorkflows_Dept] FOREIGN KEY ([dept_id]) REFERENCES [dbo].[Departments] ([dept_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table ApprovalWorkflowSteps
-- ----------------------------
ALTER TABLE [dbo].[ApprovalWorkflowSteps] ADD CONSTRAINT [FK_ApprovalSteps_Workflow] FOREIGN KEY ([workflow_id]) REFERENCES [dbo].[ApprovalWorkflows] ([workflow_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[ApprovalWorkflowSteps] ADD CONSTRAINT [FK_ApprovalSteps_Role] FOREIGN KEY ([role_id]) REFERENCES [dbo].[Roles] ([role_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table AuditLogs
-- ----------------------------
ALTER TABLE [dbo].[AuditLogs] ADD CONSTRAINT [FK_AuditLogs_User] FOREIGN KEY ([user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table auth_group_permissions
-- ----------------------------
ALTER TABLE [dbo].[auth_group_permissions] ADD CONSTRAINT [auth_group_permissions_permission_id_84c5c92e_fk_auth_permission_id] FOREIGN KEY ([permission_id]) REFERENCES [dbo].[auth_permission] ([id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[auth_group_permissions] ADD CONSTRAINT [auth_group_permissions_group_id_b120cbf9_fk_auth_group_id] FOREIGN KEY ([group_id]) REFERENCES [dbo].[auth_group] ([id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table auth_permission
-- ----------------------------
ALTER TABLE [dbo].[auth_permission] ADD CONSTRAINT [auth_permission_content_type_id_2f476e4b_fk_django_content_type_id] FOREIGN KEY ([content_type_id]) REFERENCES [dbo].[django_content_type] ([id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table CartPRItems
-- ----------------------------
ALTER TABLE [dbo].[CartPRItems] ADD CONSTRAINT [FK_CartPRItems_Cart] FOREIGN KEY ([cart_id]) REFERENCES [dbo].[Carts] ([cart_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[CartPRItems] ADD CONSTRAINT [FK_CartPRItems_PRItem] FOREIGN KEY ([pr_item_id]) REFERENCES [dbo].[PRItems] ([pr_item_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table Carts
-- ----------------------------
ALTER TABLE [dbo].[Carts] ADD CONSTRAINT [FK_Carts_Buyer] FOREIGN KEY ([buyer_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table CreditNotes
-- ----------------------------
ALTER TABLE [dbo].[CreditNotes] ADD CONSTRAINT [FK_CreditNotes_Supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([supplier_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[CreditNotes] ADD CONSTRAINT [FK_CreditNotes_Invoice] FOREIGN KEY ([invoice_id]) REFERENCES [dbo].[Invoices] ([invoice_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[CreditNotes] ADD CONSTRAINT [FK_CreditNotes_Return] FOREIGN KEY ([return_id]) REFERENCES [dbo].[ReturnOrders] ([return_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[CreditNotes] ADD CONSTRAINT [FK_CreditNotes_Payment] FOREIGN KEY ([applied_to_payment_id]) REFERENCES [dbo].[PaymentRequests] ([payment_req_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[CreditNotes] ADD CONSTRAINT [FK_CreditNotes_Creator] FOREIGN KEY ([created_by_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table DebitNotes
-- ----------------------------
ALTER TABLE [dbo].[DebitNotes] ADD CONSTRAINT [FK_DebitNotes_Supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([supplier_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[DebitNotes] ADD CONSTRAINT [FK_DebitNotes_Invoice] FOREIGN KEY ([invoice_id]) REFERENCES [dbo].[Invoices] ([invoice_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[DebitNotes] ADD CONSTRAINT [FK_DebitNotes_Payment] FOREIGN KEY ([applied_to_payment_id]) REFERENCES [dbo].[PaymentRequests] ([payment_req_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[DebitNotes] ADD CONSTRAINT [FK_DebitNotes_Creator] FOREIGN KEY ([created_by_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table Departments
-- ----------------------------
ALTER TABLE [dbo].[Departments] ADD CONSTRAINT [FK_Departments_Branch] FOREIGN KEY ([branch_id]) REFERENCES [dbo].[Branches] ([branch_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[Departments] ADD CONSTRAINT [FK_Departments_Parent] FOREIGN KEY ([parent_dept_id]) REFERENCES [dbo].[Departments] ([dept_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table django_admin_log
-- ----------------------------
ALTER TABLE [dbo].[django_admin_log] ADD CONSTRAINT [django_admin_log_content_type_id_c4bce8eb_fk_django_content_type_id] FOREIGN KEY ([content_type_id]) REFERENCES [dbo].[django_content_type] ([id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[django_admin_log] ADD CONSTRAINT [django_admin_log_user_id_c564eba6_fk_Users_user_id] FOREIGN KEY ([user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table DocumentApprovalProgress
-- ----------------------------
ALTER TABLE [dbo].[DocumentApprovalProgress] ADD CONSTRAINT [FK_DocApproval_Approver] FOREIGN KEY ([approver_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table EmailTemplates
-- ----------------------------
ALTER TABLE [dbo].[EmailTemplates] ADD CONSTRAINT [FK_EmailTemplates_UpdatedBy] FOREIGN KEY ([last_updated_by_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table Inventory
-- ----------------------------
ALTER TABLE [dbo].[Inventory] ADD CONSTRAINT [FK_Inventory_Branch] FOREIGN KEY ([branch_id]) REFERENCES [dbo].[Branches] ([branch_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[Inventory] ADD CONSTRAINT [FK_Inventory_Material] FOREIGN KEY ([material_id]) REFERENCES [dbo].[Materials] ([material_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table InvoiceMatchingResults
-- ----------------------------
ALTER TABLE [dbo].[InvoiceMatchingResults] ADD CONSTRAINT [FK_Matching_Invoice] FOREIGN KEY ([invoice_id]) REFERENCES [dbo].[Invoices] ([invoice_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[InvoiceMatchingResults] ADD CONSTRAINT [FK_Matching_IPOItem] FOREIGN KEY ([ipo_item_id]) REFERENCES [dbo].[IPOItems] ([ipo_item_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[InvoiceMatchingResults] ADD CONSTRAINT [FK_Matching_ReceiptItem] FOREIGN KEY ([receipt_item_id]) REFERENCES [dbo].[StockReceiptItems] ([receipt_item_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table Invoices
-- ----------------------------
ALTER TABLE [dbo].[Invoices] ADD CONSTRAINT [FK_Invoices_Supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([supplier_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[Invoices] ADD CONSTRAINT [FK_Invoices_IPO] FOREIGN KEY ([ipo_id]) REFERENCES [dbo].[IPOs] ([ipo_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[Invoices] ADD CONSTRAINT [FK_Invoices_Override] FOREIGN KEY ([override_by_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table IPOItems
-- ----------------------------
ALTER TABLE [dbo].[IPOItems] ADD CONSTRAINT [FK_IPOItems_IPO] FOREIGN KEY ([ipo_id]) REFERENCES [dbo].[IPOs] ([ipo_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[IPOItems] ADD CONSTRAINT [FK_IPOItems_OrderItem] FOREIGN KEY ([order_item_id]) REFERENCES [dbo].[OrderItems] ([order_item_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table IPOs
-- ----------------------------
ALTER TABLE [dbo].[IPOs] ADD CONSTRAINT [FK_IPOs_Order] FOREIGN KEY ([order_id]) REFERENCES [dbo].[Orders] ([order_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[IPOs] ADD CONSTRAINT [FK_IPOs_Supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([supplier_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[IPOs] ADD CONSTRAINT [FK_IPOs_Buyer] FOREIGN KEY ([buyer_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table Materials
-- ----------------------------
ALTER TABLE [dbo].[Materials] ADD CONSTRAINT [FK_Materials_Category] FOREIGN KEY ([category_id]) REFERENCES [dbo].[MaterialCategories] ([category_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table Notifications
-- ----------------------------
ALTER TABLE [dbo].[Notifications] ADD CONSTRAINT [FK_Notifications_Recipient] FOREIGN KEY ([recipient_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[Notifications] ADD CONSTRAINT [FK_Notifications_Template] FOREIGN KEY ([email_template_id]) REFERENCES [dbo].[EmailTemplates] ([template_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table OrderItemPRLinks
-- ----------------------------
ALTER TABLE [dbo].[OrderItemPRLinks] ADD CONSTRAINT [FK_OrderItemPRLinks_Order] FOREIGN KEY ([order_item_id]) REFERENCES [dbo].[OrderItems] ([order_item_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[OrderItemPRLinks] ADD CONSTRAINT [FK_OrderItemPRLinks_PR] FOREIGN KEY ([pr_item_id]) REFERENCES [dbo].[PRItems] ([pr_item_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table OrderItems
-- ----------------------------
ALTER TABLE [dbo].[OrderItems] ADD CONSTRAINT [FK_OrderItems_Order] FOREIGN KEY ([order_id]) REFERENCES [dbo].[Orders] ([order_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[OrderItems] ADD CONSTRAINT [FK_OrderItems_Material] FOREIGN KEY ([material_id]) REFERENCES [dbo].[Materials] ([material_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table Orders
-- ----------------------------
ALTER TABLE [dbo].[Orders] ADD CONSTRAINT [FK_Orders_Buyer] FOREIGN KEY ([buyer_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table OrderSuppliers
-- ----------------------------
ALTER TABLE [dbo].[OrderSuppliers] ADD CONSTRAINT [FK_OrderSuppliers_Order] FOREIGN KEY ([order_id]) REFERENCES [dbo].[Orders] ([order_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[OrderSuppliers] ADD CONSTRAINT [FK_OrderSuppliers_Supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([supplier_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table PaymentRequests
-- ----------------------------
ALTER TABLE [dbo].[PaymentRequests] ADD CONSTRAINT [FK_PaymentReq_Invoice] FOREIGN KEY ([invoice_id]) REFERENCES [dbo].[Invoices] ([invoice_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[PaymentRequests] ADD CONSTRAINT [FK_PaymentReq_Applicant] FOREIGN KEY ([applicant_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table PRItems
-- ----------------------------
ALTER TABLE [dbo].[PRItems] ADD CONSTRAINT [FK_PRItems_PR] FOREIGN KEY ([pr_id]) REFERENCES [dbo].[PurchaseRequisitions] ([pr_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[PRItems] ADD CONSTRAINT [FK_PRItems_Material] FOREIGN KEY ([material_id]) REFERENCES [dbo].[Materials] ([material_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table PRStatusHistory
-- ----------------------------
ALTER TABLE [dbo].[PRStatusHistory] ADD CONSTRAINT [FK_PRStatusHistory_PR] FOREIGN KEY ([pr_id]) REFERENCES [dbo].[PurchaseRequisitions] ([pr_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[PRStatusHistory] ADD CONSTRAINT [FK_PRStatusHistory_User] FOREIGN KEY ([changed_by_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table PurchaseRequisitions
-- ----------------------------
ALTER TABLE [dbo].[PurchaseRequisitions] ADD CONSTRAINT [FK_PR_Branch] FOREIGN KEY ([branch_id]) REFERENCES [dbo].[Branches] ([branch_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[PurchaseRequisitions] ADD CONSTRAINT [FK_PR_Dept] FOREIGN KEY ([dept_id]) REFERENCES [dbo].[Departments] ([dept_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[PurchaseRequisitions] ADD CONSTRAINT [FK_PR_Requester] FOREIGN KEY ([requester_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table QuotationItems
-- ----------------------------
ALTER TABLE [dbo].[QuotationItems] ADD CONSTRAINT [FK_QuotationItems_Quotation] FOREIGN KEY ([quotation_id]) REFERENCES [dbo].[Quotations] ([quotation_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[QuotationItems] ADD CONSTRAINT [FK_QuotationItems_OrderItem] FOREIGN KEY ([order_item_id]) REFERENCES [dbo].[OrderItems] ([order_item_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table QuotationRequests
-- ----------------------------
ALTER TABLE [dbo].[QuotationRequests] ADD CONSTRAINT [FK_QuotationRequests_Order] FOREIGN KEY ([order_id]) REFERENCES [dbo].[Orders] ([order_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[QuotationRequests] ADD CONSTRAINT [FK_QuotationRequests_Supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([supplier_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table Quotations
-- ----------------------------
ALTER TABLE [dbo].[Quotations] ADD CONSTRAINT [FK_Quotations_Request] FOREIGN KEY ([q_request_id]) REFERENCES [dbo].[QuotationRequests] ([q_request_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[Quotations] ADD CONSTRAINT [FK_Quotations_Supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([supplier_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table QuotationTokens
-- ----------------------------
ALTER TABLE [dbo].[QuotationTokens] ADD CONSTRAINT [FK_QuotationTokens_Request] FOREIGN KEY ([q_request_id]) REFERENCES [dbo].[QuotationRequests] ([q_request_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table QuotationVersions
-- ----------------------------
ALTER TABLE [dbo].[QuotationVersions] ADD CONSTRAINT [FK_QuotationVersions_Quotation] FOREIGN KEY ([quotation_id]) REFERENCES [dbo].[Quotations] ([quotation_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table ReturnOrderItems
-- ----------------------------
ALTER TABLE [dbo].[ReturnOrderItems] ADD CONSTRAINT [FK_ReturnOrderItems_Return] FOREIGN KEY ([return_id]) REFERENCES [dbo].[ReturnOrders] ([return_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[ReturnOrderItems] ADD CONSTRAINT [FK_ReturnOrderItems_Material] FOREIGN KEY ([material_id]) REFERENCES [dbo].[Materials] ([material_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table ReturnOrders
-- ----------------------------
ALTER TABLE [dbo].[ReturnOrders] ADD CONSTRAINT [FK_ReturnOrders_Supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([supplier_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[ReturnOrders] ADD CONSTRAINT [FK_ReturnOrders_Receipt] FOREIGN KEY ([receipt_id]) REFERENCES [dbo].[StockReceipts] ([receipt_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[ReturnOrders] ADD CONSTRAINT [FK_ReturnOrders_Creator] FOREIGN KEY ([created_by_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table RolePermissions
-- ----------------------------
ALTER TABLE [dbo].[RolePermissions] ADD CONSTRAINT [FK_RolePermissions_Role] FOREIGN KEY ([role_id]) REFERENCES [dbo].[Roles] ([role_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[RolePermissions] ADD CONSTRAINT [FK_RolePermissions_Permission] FOREIGN KEY ([permission_id]) REFERENCES [dbo].[Permissions] ([permission_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table StockIssueItems
-- ----------------------------
ALTER TABLE [dbo].[StockIssueItems] ADD CONSTRAINT [FK_StockIssueItems_Issue] FOREIGN KEY ([issue_id]) REFERENCES [dbo].[StockIssues] ([issue_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[StockIssueItems] ADD CONSTRAINT [FK_StockIssueItems_Material] FOREIGN KEY ([material_id]) REFERENCES [dbo].[Materials] ([material_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table StockIssues
-- ----------------------------
ALTER TABLE [dbo].[StockIssues] ADD CONSTRAINT [FK_StockIssues_Receiver] FOREIGN KEY ([receiver_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[StockIssues] ADD CONSTRAINT [FK_StockIssues_PR] FOREIGN KEY ([pr_id]) REFERENCES [dbo].[PurchaseRequisitions] ([pr_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[StockIssues] ADD CONSTRAINT [FK_StockIssues_Dept] FOREIGN KEY ([dept_id]) REFERENCES [dbo].[Departments] ([dept_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[StockIssues] ADD CONSTRAINT [FK_StockIssues_Keeper] FOREIGN KEY ([warehouse_keeper_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table StockReceiptItems
-- ----------------------------
ALTER TABLE [dbo].[StockReceiptItems] ADD CONSTRAINT [FK_StockReceiptItems_Receipt] FOREIGN KEY ([receipt_id]) REFERENCES [dbo].[StockReceipts] ([receipt_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[StockReceiptItems] ADD CONSTRAINT [FK_StockReceiptItems_Material] FOREIGN KEY ([material_id]) REFERENCES [dbo].[Materials] ([material_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table StockReceipts
-- ----------------------------
ALTER TABLE [dbo].[StockReceipts] ADD CONSTRAINT [FK_StockReceipts_IPO] FOREIGN KEY ([ipo_id]) REFERENCES [dbo].[IPOs] ([ipo_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[StockReceipts] ADD CONSTRAINT [FK_StockReceipts_Keeper] FOREIGN KEY ([warehouse_keeper_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table SupplierContractPrices
-- ----------------------------
ALTER TABLE [dbo].[SupplierContractPrices] ADD CONSTRAINT [FK_ContractPrices_Supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([supplier_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[SupplierContractPrices] ADD CONSTRAINT [FK_ContractPrices_Material] FOREIGN KEY ([material_id]) REFERENCES [dbo].[Materials] ([material_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table SupplierEvaluationCriteria
-- ----------------------------
ALTER TABLE [dbo].[SupplierEvaluationCriteria] ADD CONSTRAINT [FK_EvalCriteria_Evaluation] FOREIGN KEY ([evaluation_id]) REFERENCES [dbo].[SupplierEvaluations] ([evaluation_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table SupplierEvaluations
-- ----------------------------
ALTER TABLE [dbo].[SupplierEvaluations] ADD CONSTRAINT [FK_SupplierEval_Supplier] FOREIGN KEY ([supplier_id]) REFERENCES [dbo].[Suppliers] ([supplier_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[SupplierEvaluations] ADD CONSTRAINT [FK_SupplierEval_Evaluator] FOREIGN KEY ([evaluator_user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table token_blacklist_blacklistedtoken
-- ----------------------------
ALTER TABLE [dbo].[token_blacklist_blacklistedtoken] ADD CONSTRAINT [token_blacklist_blacklistedtoken_token_id_3cc7fe56_fk] FOREIGN KEY ([token_id]) REFERENCES [dbo].[token_blacklist_outstandingtoken] ([id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table token_blacklist_outstandingtoken
-- ----------------------------
ALTER TABLE [dbo].[token_blacklist_outstandingtoken] ADD CONSTRAINT [token_blacklist_outstandingtoken_user_id_83bc629a_fk_Users_user_id] FOREIGN KEY ([user_id]) REFERENCES [dbo].[Users] ([user_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


-- ----------------------------
-- Foreign Keys structure for table Users
-- ----------------------------
ALTER TABLE [dbo].[Users] ADD CONSTRAINT [FK_Users_Branch] FOREIGN KEY ([branch_id]) REFERENCES [dbo].[Branches] ([branch_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[Users] ADD CONSTRAINT [FK_Users_Dept] FOREIGN KEY ([dept_id]) REFERENCES [dbo].[Departments] ([dept_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

ALTER TABLE [dbo].[Users] ADD CONSTRAINT [FK_Users_Role] FOREIGN KEY ([role_id]) REFERENCES [dbo].[Roles] ([role_id]) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

