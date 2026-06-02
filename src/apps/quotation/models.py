"""
Module 5: Quotation & Vendor Portal
Bảng: QuotationRequests, QuotationTokens, Quotations,
      QuotationItems, QuotationVersions
"""
from django.db import models

from apps.cart_order.models import Order, OrderItem
from apps.master_data.models import Supplier


class QuotationRequest(models.Model):
    q_request_id = models.AutoField(primary_key=True)
    order = models.ForeignKey(
        Order, on_delete=models.PROTECT, db_column="order_id", related_name="quotation_requests"
    )
    supplier = models.ForeignKey(
        Supplier, on_delete=models.PROTECT, db_column="supplier_id"
    )
    deadline_submission = models.DateTimeField()
    sent_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "QuotationRequests"
        unique_together = ("order", "supplier")


class QuotationToken(models.Model):
    token_id = models.AutoField(primary_key=True)
    q_request = models.OneToOneField(
        QuotationRequest, on_delete=models.CASCADE,
        db_column="q_request_id", related_name="token"
    )
    token = models.CharField(max_length=128, unique=True)   # SHA-256 hex (64 chars)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    used_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "QuotationTokens"


class Quotation(models.Model):
    quotation_id = models.AutoField(primary_key=True)
    q_request = models.OneToOneField(
        QuotationRequest, on_delete=models.PROTECT,
        db_column="q_request_id", related_name="quotation"
    )
    supplier = models.ForeignKey(
        Supplier, on_delete=models.PROTECT, db_column="supplier_id"
    )
    submitted_at = models.DateTimeField(auto_now_add=True)
    delivery_lead_time_days = models.IntegerField()
    payment_terms_note = models.CharField(max_length=200, null=True, blank=True)
    total_quote_amount = models.DecimalField(max_digits=18, decimal_places=2, default=0)
    is_selected = models.BooleanField(default=False)

    class Meta:
        db_table = "Quotations"


class QuotationItem(models.Model):
    q_item_id = models.AutoField(primary_key=True)
    quotation = models.ForeignKey(
        Quotation, on_delete=models.CASCADE, db_column="quotation_id", related_name="items"
    )
    order_item = models.ForeignKey(
        OrderItem, on_delete=models.PROTECT, db_column="order_item_id"
    )
    quoted_unit_price = models.DecimalField(max_digits=18, decimal_places=2)
    supplier_note = models.CharField(max_length=300, null=True, blank=True)

    class Meta:
        db_table = "QuotationItems"

    def clean(self):
        from django.core.exceptions import ValidationError
        if self.quoted_unit_price < 0:
            raise ValidationError("Đơn giá không được âm.")


class QuotationVersion(models.Model):
    """Lưu vết mỗi lần NCC submit lại báo giá."""
    version_id = models.AutoField(primary_key=True)
    quotation = models.ForeignKey(
        Quotation, on_delete=models.CASCADE,
        db_column="quotation_id", related_name="versions"
    )
    version_number = models.IntegerField()
    is_current = models.BooleanField(default=False)
    snapshot_total_amount = models.DecimalField(max_digits=18, decimal_places=2)
    snapshot_lead_time_days = models.IntegerField()
    snapshot_payment_terms = models.CharField(max_length=200, null=True, blank=True)
    snapshot_items_json = models.TextField()    # JSON chụp ảnh QuotationItems
    submitted_at = models.DateTimeField(auto_now_add=True)
    submitted_ip = models.CharField(max_length=45, null=True, blank=True)
    change_summary = models.CharField(max_length=500, null=True, blank=True)

    class Meta:
        db_table = "QuotationVersions"
        unique_together = ("quotation", "version_number")
        ordering = ["-version_number"]
