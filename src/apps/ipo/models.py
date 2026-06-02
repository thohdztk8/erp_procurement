"""
Module 6: Internal Purchase Order (IPO) — đa phiên bản.
Bảng: IPOs, IPOItems
"""
from django.db import models

from apps.authentication.models import User
from apps.cart_order.models import Order, OrderItem
from apps.master_data.models import Supplier


class IPO(models.Model):
    STATUS_CHOICES = [
        ("DRAFT", "Nháp"),
        ("PENDING", "Chờ duyệt"),
        ("APPROVED", "Đã duyệt"),
        ("REJECTED", "Từ chối"),
    ]

    ipo_id = models.AutoField(primary_key=True)
    ipo_code = models.CharField(max_length=30)           # Mã chung, không unique (nhiều version)
    version = models.IntegerField(default=1)
    is_latest = models.BooleanField(default=True)        # Chỉ 1 version is_latest=True tại 1 thời điểm
    order = models.ForeignKey(
        Order, on_delete=models.PROTECT, db_column="order_id", related_name="ipos"
    )
    supplier = models.ForeignKey(
        Supplier, on_delete=models.PROTECT, db_column="supplier_id"
    )
    buyer = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="buyer_user_id", related_name="ipos"
    )
    total_amount = models.DecimalField(max_digits=18, decimal_places=2)
    ipo_status = models.CharField(max_length=30, choices=STATUS_CHOICES, default="DRAFT")
    signed_pdf_path = models.CharField(max_length=500, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "IPOs"

    def __str__(self):
        return f"{self.ipo_code} v{self.version}"


class IPOItem(models.Model):
    ipo_item_id = models.AutoField(primary_key=True)
    ipo = models.ForeignKey(
        IPO, on_delete=models.CASCADE, db_column="ipo_id", related_name="items"
    )
    order_item = models.ForeignKey(
        OrderItem, on_delete=models.PROTECT, db_column="order_item_id"
    )
    qty_final = models.DecimalField(max_digits=18, decimal_places=4)
    unit_price = models.DecimalField(max_digits=18, decimal_places=2)
    total_price = models.DecimalField(max_digits=18, decimal_places=2)

    class Meta:
        db_table = "IPOItems"

    def clean(self):
        from django.core.exceptions import ValidationError
        if self.qty_final <= 0:
            raise ValidationError("qty_final phải lớn hơn 0.")
