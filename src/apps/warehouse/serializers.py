import json

from rest_framework import serializers

from .models import Inventory, WarehouseReceipt, WarehouseReceiptItem, WarehouseReturn


class ReceiptItemCreateSerializer(serializers.Serializer):
    ipo_item_id = serializers.IntegerField()
    qty_received = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0.0001)
    qty_passed = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0)
    qty_failed = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0)
    photo_paths = serializers.ListField(
        child=serializers.CharField(max_length=500),
        required=False, default=list
    )
    failure_reason = serializers.CharField(required=False, allow_blank=True, max_length=500)

    def validate(self, attrs):
        qty_received = attrs["qty_received"]
        qty_passed = attrs["qty_passed"]
        qty_failed = attrs["qty_failed"]

        if qty_passed + qty_failed != qty_received:
            raise serializers.ValidationError(
                f"qty_received ({qty_received}) phải bằng "
                f"qty_passed ({qty_passed}) + qty_failed ({qty_failed})."
            )
        if qty_failed > 0 and not attrs.get("photo_paths"):
            raise serializers.ValidationError(
                "Bắt buộc đính kèm ảnh minh chứng khi có hàng lỗi (qty_failed > 0)."
            )
        return attrs


class ReceiptCreateSerializer(serializers.Serializer):
    ipo_id = serializers.IntegerField()
    notes = serializers.CharField(required=False, allow_blank=True, max_length=500)
    items = ReceiptItemCreateSerializer(many=True, min_length=1)

    def validate_ipo_id(self, value):
        from apps.ipo.models import IPO
        try:
            IPO.objects.get(ipo_id=value, ipo_status="APPROVED", is_latest=True)
        except IPO.DoesNotExist:
            raise serializers.ValidationError("IPO không tồn tại hoặc chưa được phê duyệt.")
        return value


class ReceiptItemSerializer(serializers.ModelSerializer):
    photo_paths = serializers.SerializerMethodField()

    class Meta:
        model = WarehouseReceiptItem
        fields = [
            "receipt_item_id", "ipo_item_id",
            "qty_received", "qty_passed", "qty_failed",
            "photo_paths", "failure_reason",
        ]

    def get_photo_paths(self, obj):
        if obj.photo_paths:
            try:
                return json.loads(obj.photo_paths)
            except (json.JSONDecodeError, TypeError):
                return []
        return []


class ReceiptSerializer(serializers.ModelSerializer):
    receiver_name = serializers.CharField(source="receiver.full_name", read_only=True)
    items = ReceiptItemSerializer(many=True, read_only=True)

    class Meta:
        model = WarehouseReceipt
        fields = ["receipt_id", "receipt_code", "ipo_id", "receiver_name", "items", "receipt_date", "notes"]


class InventorySerializer(serializers.ModelSerializer):
    material_code = serializers.CharField(source="material.material_code", read_only=True)
    material_name = serializers.CharField(source="material.material_name", read_only=True)
    uom = serializers.CharField(source="material.uom", read_only=True)

    class Meta:
        model = Inventory
        fields = [
            "inventory_id", "material_id",
            "material_code", "material_name", "uom",
            "qty_available", "qty_quarantine", "last_updated",
        ]


class WarehouseReturnSerializer(serializers.ModelSerializer):
    class Meta:
        model = WarehouseReturn
        fields = [
            "return_id", "return_code", "receipt_item_id", "supplier_id",
            "qty_returned", "return_reason", "return_status", "created_at",
        ]
