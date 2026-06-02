from rest_framework import serializers

from .models import Cart, CartPRItem, Order, OrderItem, OrderSupplier


class AddItemsToCartSerializer(serializers.Serializer):
    cart_title = serializers.CharField(max_length=150)
    pr_item_ids = serializers.ListField(
        child=serializers.IntegerField(), min_length=1
    )

    def validate_pr_item_ids(self, value):
        from apps.purchase_request.models import PRItem
        existing = set(
            PRItem.objects.filter(
                pr_item_id__in=value,
                pr__pr_status="APPROVED",
                item_status="PENDING",
            ).values_list("pr_item_id", flat=True)
        )
        invalid = set(value) - existing
        if invalid:
            raise serializers.ValidationError(
                f"Các dòng hàng sau không hợp lệ hoặc chưa được duyệt: {list(invalid)}"
            )
        return value


class CartItemSerializer(serializers.ModelSerializer):
    pr_item_id = serializers.IntegerField(source="pr_item.pr_item_id", read_only=True)
    material_name = serializers.SerializerMethodField()
    qty_requested = serializers.DecimalField(
        source="pr_item.qty_requested", max_digits=18, decimal_places=4, read_only=True
    )

    class Meta:
        model = CartPRItem
        fields = ["pr_item_id", "material_name", "qty_requested", "qty_in_cart", "added_at"]

    def get_material_name(self, obj):
        pi = obj.pr_item
        return pi.material.material_name if pi.material_id else pi.material_name_other


class CartSerializer(serializers.ModelSerializer):
    buyer_name = serializers.CharField(source="buyer.full_name", read_only=True)
    items = CartItemSerializer(source="cart_items", many=True, read_only=True)

    class Meta:
        model = Cart
        fields = ["cart_id", "cart_title", "buyer_name", "items", "created_at"]


class OrderItemSerializer(serializers.ModelSerializer):
    material_name = serializers.SerializerMethodField()

    class Meta:
        model = OrderItem
        fields = ["order_item_id", "material_id", "material_name", "material_name_other", "qty_total_ordered"]

    def get_material_name(self, obj):
        return obj.material.material_name if obj.material_id else obj.material_name_other


class OrderListSerializer(serializers.ModelSerializer):
    buyer_name = serializers.CharField(source="buyer.full_name", read_only=True)
    item_count = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = ["order_id", "order_code", "order_status", "buyer_name", "item_count", "created_at"]

    def get_item_count(self, obj):
        return obj.items.count()


class OrderDetailSerializer(serializers.ModelSerializer):
    buyer_name = serializers.CharField(source="buyer.full_name", read_only=True)
    items = OrderItemSerializer(many=True, read_only=True)
    suppliers = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = ["order_id", "order_code", "order_status", "buyer_name", "items", "suppliers", "created_at"]

    def get_suppliers(self, obj):
        return list(
            obj.order_suppliers.values("supplier__supplier_id", "supplier__supplier_name", "assigned_at")
        )


class AddSuppliersSerializer(serializers.Serializer):
    supplier_ids = serializers.ListField(child=serializers.IntegerField(), min_length=1)

    def validate_supplier_ids(self, value):
        from apps.master_data.models import Supplier
        existing = set(
            Supplier.objects.filter(supplier_id__in=value, is_active=True)
            .values_list("supplier_id", flat=True)
        )
        invalid = set(value) - existing
        if invalid:
            raise serializers.ValidationError(f"NCC không tồn tại: {list(invalid)}")
        return value
