from rest_framework import serializers

from .models import IPO, IPOItem


class IPOItemCreateSerializer(serializers.Serializer):
    order_item_id = serializers.IntegerField()
    qty_final = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0.0001)
    unit_price = serializers.DecimalField(max_digits=18, decimal_places=2, min_value=0)


class IPOCreateSerializer(serializers.Serializer):
    order_id = serializers.IntegerField()
    supplier_id = serializers.IntegerField()
    items = IPOItemCreateSerializer(many=True, min_length=1)

    def validate_order_id(self, value):
        from apps.cart_order.models import Order
        try:
            Order.objects.get(order_id=value, order_status="QUOTE_CLOSED")
        except Order.DoesNotExist:
            raise serializers.ValidationError("Đơn hàng không tồn tại hoặc chưa đóng thầu.")
        return value

    def validate_supplier_id(self, value):
        from apps.master_data.models import Supplier
        try:
            Supplier.objects.get(supplier_id=value, is_active=True)
        except Supplier.DoesNotExist:
            raise serializers.ValidationError("Nhà cung cấp không tồn tại.")
        return value


class IPOItemSerializer(serializers.ModelSerializer):
    material_name = serializers.SerializerMethodField()

    class Meta:
        model = IPOItem
        fields = ["ipo_item_id", "order_item_id", "material_name", "qty_final", "unit_price", "total_price"]

    def get_material_name(self, obj):
        oi = obj.order_item
        return oi.material.material_name if oi.material_id else oi.material_name_other


class IPOListSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source="supplier.supplier_name", read_only=True)
    buyer_name = serializers.CharField(source="buyer.full_name", read_only=True)

    class Meta:
        model = IPO
        fields = [
            "ipo_id", "ipo_code", "version", "is_latest",
            "ipo_status", "total_amount", "supplier_name", "buyer_name", "created_at",
        ]


class IPODetailSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source="supplier.supplier_name", read_only=True)
    buyer_name = serializers.CharField(source="buyer.full_name", read_only=True)
    items = IPOItemSerializer(many=True, read_only=True)

    class Meta:
        model = IPO
        fields = [
            "ipo_id", "ipo_code", "version", "is_latest",
            "ipo_status", "total_amount",
            "supplier_name", "buyer_name",
            "signed_pdf_path", "items",
            "created_at", "updated_at",
        ]


class IPOApproveSerializer(serializers.Serializer):
    ipo_id = serializers.IntegerField()
    action = serializers.ChoiceField(choices=["APPROVE", "REJECT"])
    comment = serializers.CharField(required=False, allow_blank=True, max_length=500)

    def validate(self, attrs):
        if attrs["action"] == "REJECT" and not attrs.get("comment", "").strip():
            raise serializers.ValidationError({"comment": "Bắt buộc nhập lý do từ chối."})
        return attrs
