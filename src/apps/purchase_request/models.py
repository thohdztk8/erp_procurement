"""
Module 3: Purchase Request (PR)
Bảng: PurchaseRequisitions, PRItems, DocumentApprovalProgress, PRStatusHistory
"""
from django.db import models

from apps.authentication.models import Branch, Department, User
from apps.master_data.models import Material


class PurchaseRequisition(models.Model):
    PRIORITY_CHOICES = [("NORMAL", "Thường"), ("URGENT", "Khẩn")]
    STATUS_CHOICES = [
        ("DRAFT", "Nháp"),
        ("PENDING", "Chờ duyệt"),
        ("APPROVED", "Đã duyệt"),
        ("REJECTED", "Từ chối"),
        ("CANCELLED", "Hủy"),
    ]

    pr_id = models.AutoField(primary_key=True)
    pr_code = models.CharField(max_length=30, unique=True)
    requester = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="requester_user_id",
        related_name="purchase_requests"
    )
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, db_column="branch_id")
    dept = models.ForeignKey(Department, on_delete=models.PROTECT, db_column="dept_id")
    priority_level = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default="NORMAL")
    urgent_reason = models.CharField(max_length=500, null=True, blank=True)
    urgency_impact = models.CharField(max_length=500, null=True, blank=True)
    pr_status = models.CharField(max_length=30, choices=STATUS_CHOICES, default="DRAFT")
    total_estimated_amount = models.DecimalField(max_digits=18, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "PurchaseRequisitions"

    def __str__(self):
        return self.pr_code


class PRItem(models.Model):
    ITEM_STATUS_CHOICES = [
        ("PENDING", "Chờ xử lý"),
        ("PARTIAL", "Đang xử lý"),
        ("COMPLETED", "Hoàn thành"),
    ]

    pr_item_id = models.AutoField(primary_key=True)
    pr = models.ForeignKey(
        PurchaseRequisition, on_delete=models.CASCADE,
        db_column="pr_id", related_name="items"
    )
    # Kiểm tra loại trừ chéo: material_id XOR material_name_other
    material = models.ForeignKey(
        Material, on_delete=models.PROTECT, db_column="material_id",
        null=True, blank=True
    )
    material_name_other = models.CharField(max_length=300, null=True, blank=True)
    qty_requested = models.DecimalField(max_digits=18, decimal_places=4)
    qty_ordered = models.DecimalField(max_digits=18, decimal_places=4, default=0)
    qty_received = models.DecimalField(max_digits=18, decimal_places=4, default=0)
    estimated_unit_price = models.DecimalField(max_digits=18, decimal_places=2, default=0)
    required_deadline = models.DateTimeField()
    item_status = models.CharField(max_length=30, choices=ITEM_STATUS_CHOICES, default="PENDING")

    class Meta:
        db_table = "PRItems"

    def clean(self):
        from django.core.exceptions import ValidationError
        has_material = bool(self.material_id)
        has_other = bool(self.material_name_other and self.material_name_other.strip())
        if not has_material and not has_other:
            raise ValidationError("Phải nhập material_id hoặc material_name_other.")
        if has_material and has_other:
            raise ValidationError("Không được điền cả material_id lẫn material_name_other.")


class DocumentApprovalProgress(models.Model):
    STATUS_CHOICES = [("PENDING", "Chờ"), ("APPROVED", "Duyệt"), ("REJECTED", "Từ chối")]

    progress_id = models.AutoField(primary_key=True)
    document_type = models.CharField(max_length=50)    # PR | IPO
    document_id = models.IntegerField()
    step_sequence = models.IntegerField()
    approver = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="approver_user_id",
        null=True, blank=True
    )
    approval_status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="PENDING")
    comment = models.CharField(max_length=500, null=True, blank=True)
    action_date = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "DocumentApprovalProgress"


class PRStatusHistory(models.Model):
    history_id = models.AutoField(primary_key=True)
    pr = models.ForeignKey(
        PurchaseRequisition, on_delete=models.CASCADE,
        db_column="pr_id", related_name="status_history"
    )
    from_status = models.CharField(max_length=30)
    to_status = models.CharField(max_length=30)
    changed_by = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="changed_by_user_id"
    )
    note = models.CharField(max_length=500, null=True, blank=True)
    changed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "PRStatusHistory"
