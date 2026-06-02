"""
Module 4: Cart & Order — Gom giỏ hàng và điều phối đặt hàng.
Bảng: Carts, CartPRItems, Orders, OrderItems, OrderItemPRLinks, OrderSuppliers
"""
from django.db import models

from apps.authentication.models import User
from apps.master_data.models import Material, Supplier
from apps.purchase_request.models import PRItem


class Cart(models.Model):
    cart_id = models.AutoField(primary_key=True)
    cart_title = models.CharField(max_length=150)
    buyer = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="buyer_user_id", related_name="carts"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "Carts"

    def __str__(self):
        return self.cart_title


class CartPRItem(models.Model):
    cart = models.ForeignKey(
        Cart, on_delete=models.CASCADE, db_column="cart_id", related_name="cart_items"
    )
    pr_item = models.ForeignKey(
        PRItem, on_delete=models.PROTECT, db_column="pr_item_id"
    )
    qty_in_cart = models.DecimalField(max_digits=18, decimal_places=4)
    added_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "CartPRItems"
        unique_together = ("cart", "pr_item")

    def clean(self):
        from django.core.exceptions import ValidationError
        if self.qty_in_cart <= 0:
            raise ValidationError("qty_in_cart phải lớn hơn 0.")


class Order(models.Model):
    STATUS_CHOICES = [
        ("DRAFT", "Nháp"),
        ("QUOTING", "Đang báo giá"),
        ("QUOTE_CLOSED", "Đã đóng thầu"),
        ("COMPLETED", "Hoàn thành"),
        ("CANCELLED", "Hủy"),
    ]

    order_id = models.AutoField(primary_key=True)
    order_code = models.CharField(max_length=30, unique=True)
    buyer = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="buyer_user_id", related_name="orders"
    )
    order_status = models.CharField(max_length=30, choices=STATUS_CHOICES, default="DRAFT")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "Orders"

    def __str__(self):
        return self.order_code


class OrderItem(models.Model):
    order_item_id = models.AutoField(primary_key=True)
    order = models.ForeignKey(
        Order, on_delete=models.CASCADE, db_column="order_id", related_name="items"
    )
    material = models.ForeignKey(
        Material, on_delete=models.PROTECT, db_column="material_id", null=True, blank=True
    )
    material_name_other = models.CharField(max_length=300, null=True, blank=True)
    qty_total_ordered = models.DecimalField(max_digits=18, decimal_places=4)

    class Meta:
        db_table = "OrderItems"

    def clean(self):
        from django.core.exceptions import ValidationError
        has_material = bool(self.material_id)
        has_other = bool(self.material_name_other and self.material_name_other.strip())
        if not has_material and not has_other:
            raise ValidationError("Phải có material_id hoặc material_name_other.")
        if has_material and has_other:
            raise ValidationError("Không được điền cả hai.")
        if self.qty_total_ordered <= 0:
            raise ValidationError("qty_total_ordered phải lớn hơn 0.")


class OrderItemPRLink(models.Model):
    """Bảng phân rã: OrderItem ← nhiều PRItem"""
    order_item = models.ForeignKey(
        OrderItem, on_delete=models.CASCADE, db_column="order_item_id", related_name="pr_links"
    )
    pr_item = models.ForeignKey(
        PRItem, on_delete=models.PROTECT, db_column="pr_item_id"
    )
    qty_linked = models.DecimalField(max_digits=18, decimal_places=4)

    class Meta:
        db_table = "OrderItemPRLinks"
        unique_together = ("order_item", "pr_item")


class OrderSupplier(models.Model):
    """Danh sách NCC được mời tham gia báo giá cho Order"""
    order = models.ForeignKey(
        Order, on_delete=models.CASCADE, db_column="order_id", related_name="order_suppliers"
    )
    supplier = models.ForeignKey(
        Supplier, on_delete=models.PROTECT, db_column="supplier_id"
    )
    assigned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "OrderSuppliers"
        unique_together = ("order", "supplier")
