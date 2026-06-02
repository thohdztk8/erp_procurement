"""
Module 7: Warehouse — IQC, Nhận/Xuất/Trả hàng, Inventory.
Bảng DB thực tế:
  StockReceipts, StockReceiptItems   (Django cũ dùng WarehouseReceipts/Items — ĐÃ SỬA)
  Inventory                          (thêm branch_id, qty_on_hand — ĐÃ SỬA)
  StockIssues, StockIssueItems       (Django cũ gộp 1 model WarehouseIssue — ĐÃ TÁCH)
  ReturnOrders, ReturnOrderItems     (Django cũ gộp 1 model WarehouseReturn — ĐÃ TÁCH)
"""
from django.db import models

from apps.authentication.models import Branch, Department, User
from apps.ipo.models import IPO, IPOItem
from apps.master_data.models import Material, Supplier
from apps.purchase_request.models import PurchaseRequisition


# ── StockReceipts (cũ: WarehouseReceipts) ─────────────────────
class StockReceipt(models.Model):
    receipt_id = models.AutoField(primary_key=True)
    receipt_code = models.CharField(max_length=30, unique=True)
    ipo = models.ForeignKey(
        IPO, on_delete=models.PROTECT, db_column="ipo_id", related_name="receipts"
    )
    warehouse_keeper = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="warehouse_keeper_id"
    )
    received_at = models.DateTimeField(auto_now_add=True)
    delivery_note_ref = models.CharField(max_length=100, null=True, blank=True)
    note = models.CharField(max_length=500, null=True, blank=True)

    class Meta:
        db_table = "StockReceipts"

    def __str__(self):
        return self.receipt_code


# ── StockReceiptItems (cũ: WarehouseReceiptItems) ─────────────
class StockReceiptItem(models.Model):
    receipt_item_id = models.AutoField(primary_key=True)
    receipt = models.ForeignKey(
        StockReceipt, on_delete=models.CASCADE,
        db_column="receipt_id", related_name="items"
    )
    # FIX: DB cho phép material_id OR material_name_other (giống OrderItems/PRItems)
    material = models.ForeignKey(
        Material, on_delete=models.PROTECT, db_column="material_id", null=True, blank=True
    )
    material_name_other = models.CharField(max_length=300, null=True, blank=True)
    qty_ordered = models.DecimalField(max_digits=18, decimal_places=4)
    qty_received = models.DecimalField(max_digits=18, decimal_places=4)
    qty_passed = models.DecimalField(max_digits=18, decimal_places=4)
    qty_failed = models.DecimalField(max_digits=18, decimal_places=4)
    photo_paths = models.TextField(null=True, blank=True)    # JSON array

    class Meta:
        db_table = "StockReceiptItems"

    def clean(self):
        from django.core.exceptions import ValidationError
        if self.qty_passed + self.qty_failed != self.qty_received:
            raise ValidationError(
                f"qty_received ({self.qty_received}) phải bằng "
                f"qty_passed ({self.qty_passed}) + qty_failed ({self.qty_failed})."
            )
        if self.qty_failed > 0 and not self.photo_paths:
            raise ValidationError("Bắt buộc đính kèm ảnh minh chứng khi có hàng lỗi (qty_failed > 0).")


# ── Inventory ──────────────────────────────────────────────────
class Inventory(models.Model):
    # FIX: thêm branch_id (NOT NULL), qty_on_hand; đổi OneToOne → FK; sửa last_updated → last_updated_at
    inventory_id = models.AutoField(primary_key=True)
    branch = models.ForeignKey(
        Branch, on_delete=models.PROTECT, db_column="branch_id"
    )
    material = models.ForeignKey(
        Material, on_delete=models.PROTECT, db_column="material_id"
    )
    qty_on_hand = models.DecimalField(max_digits=18, decimal_places=4, default=0)
    qty_available = models.DecimalField(max_digits=18, decimal_places=4, default=0)
    qty_quarantine = models.DecimalField(max_digits=18, decimal_places=4, default=0)
    last_updated_at = models.DateTimeField(auto_now=True, db_column="last_updated_at")

    class Meta:
        db_table = "Inventory"
        unique_together = (("branch", "material"),)

    def __str__(self):
        return f"Inventory [{self.material.material_code}] @ Branch {self.branch_id}"


# ── StockIssues (cũ: WarehouseIssue — ĐÃ TÁCH header/detail) ──
class StockIssue(models.Model):
    issue_id = models.AutoField(primary_key=True)
    issue_code = models.CharField(max_length=30, unique=True)
    pr = models.ForeignKey(
        PurchaseRequisition, on_delete=models.SET_NULL,
        null=True, blank=True, db_column="pr_id"
    )
    dept = models.ForeignKey(
        Department, on_delete=models.PROTECT, db_column="dept_id"
    )
    warehouse_keeper = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="warehouse_keeper_id",
        related_name="kept_issues"
    )
    receiver = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="receiver_user_id",
        related_name="received_issues"
    )
    issued_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "StockIssues"

    def __str__(self):
        return self.issue_code


class StockIssueItem(models.Model):
    issue_item_id = models.AutoField(primary_key=True)
    issue = models.ForeignKey(
        StockIssue, on_delete=models.CASCADE,
        db_column="issue_id", related_name="items"
    )
    material = models.ForeignKey(
        Material, on_delete=models.PROTECT, db_column="material_id"
    )
    qty_issued = models.DecimalField(max_digits=18, decimal_places=4)
    quality_rating = models.IntegerField(null=True, blank=True)  # 1-5

    class Meta:
        db_table = "StockIssueItems"


# ── ReturnOrders (cũ: WarehouseReturn — ĐÃ TÁCH header/detail) ─
class ReturnOrder(models.Model):
    STATUS_CHOICES = [
        ("DRAFT", "Nháp"),
        ("SENT", "Đã gửi NCC"),
        ("RESOLVED", "Đã xử lý"),
    ]

    return_id = models.AutoField(primary_key=True)
    return_code = models.CharField(max_length=30, unique=True)
    supplier = models.ForeignKey(
        Supplier, on_delete=models.PROTECT, db_column="supplier_id"
    )
    receipt = models.ForeignKey(
        StockReceipt, on_delete=models.PROTECT, db_column="receipt_id"
    )
    created_by = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="created_by_user_id"
    )
    return_status = models.CharField(max_length=30, choices=STATUS_CHOICES, default="DRAFT")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "ReturnOrders"

    def __str__(self):
        return self.return_code


class ReturnOrderItem(models.Model):
    return_item_id = models.AutoField(primary_key=True)
    return_order = models.ForeignKey(
        ReturnOrder, on_delete=models.CASCADE,
        db_column="return_id", related_name="items"
    )
    material = models.ForeignKey(
        Material, on_delete=models.PROTECT, db_column="material_id"
    )
    qty_returned = models.DecimalField(max_digits=18, decimal_places=4)
    reason = models.CharField(max_length=300, null=True, blank=True)

    class Meta:
        db_table = "ReturnOrderItems"


# ── Backwards-compat aliases (để services/views cũ ít bị ảnh hưởng) ──
WarehouseReceipt = StockReceipt
WarehouseReceiptItem = StockReceiptItem
WarehouseIssue = StockIssue
WarehouseReturn = ReturnOrder
