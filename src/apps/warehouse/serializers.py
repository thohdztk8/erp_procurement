import json

from rest_framework import serializers

from .models import Inventory, WarehouseReceipt, WarehouseReceiptItem, WarehouseReturn, StockIssue, StockIssueItem


class ReceiptItemCreateSerializer(serializers.Serializer):
    material_id = serializers.IntegerField(required=False, allow_null=True)
    material_name_other = serializers.CharField(required=False, allow_blank=True, max_length=300)
    qty_ordered = serializers.DecimalField(max_digits=18, decimal_places=4)
    qty_received = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0.0001)
    qty_passed = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0)
    qty_failed = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0)
    photo_paths = serializers.ListField(
        child=serializers.CharField(max_length=500),
        required=False, default=list
    )

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
    branch_id = serializers.IntegerField()
    notes = serializers.CharField(required=False, allow_blank=True, max_length=500)
    items = ReceiptItemCreateSerializer(many=True, min_length=1)

    def validate_branch_id(self, value):
        from apps.authentication.models import Branch
        try:
            Branch.objects.get(branch_id=value, is_active=True)
        except Branch.DoesNotExist:
            raise serializers.ValidationError("Chi nhánh không hợp lệ.")
        return value

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
            "receipt_item_id", "material_id", "material_name_other",
            "qty_ordered", "qty_received", "qty_passed", "qty_failed",
            "photo_paths",
        ]

    def get_photo_paths(self, obj):
        if obj.photo_paths:
            try:
                return json.loads(obj.photo_paths)
            except (json.JSONDecodeError, TypeError):
                return []
        return []


class ReceiptSerializer(serializers.ModelSerializer):
    warehouse_keeper_name = serializers.CharField(source="warehouse_keeper.full_name", read_only=True)
    items = ReceiptItemSerializer(many=True, read_only=True)

    class Meta:
        model = WarehouseReceipt
        fields = ["receipt_id", "receipt_code", "ipo_id", "warehouse_keeper_name", "items", "received_at", "note", "delivery_note_ref"]


class InventorySerializer(serializers.ModelSerializer):
    material_code = serializers.CharField(source="material.material_code", read_only=True)
    material_name = serializers.CharField(source="material.material_name", read_only=True)
    uom = serializers.CharField(source="material.uom", read_only=True)

    branch_name = serializers.CharField(source="branch.branch_name", read_only=True)

    class Meta:
        model = Inventory
        fields = [
            "inventory_id", "material_id",
            "material_code", "material_name", "uom",
            "branch_id", "branch_name",
            "qty_available", "qty_quarantine", "qty_on_hand", "last_updated_at",
        ]


class WarehouseReturnSerializer(serializers.ModelSerializer):
    class Meta:
        model = WarehouseReturn
        fields = [
            "return_id", "return_code", "receipt_id", "supplier_id",
            "return_status", "created_at",
        ]

class ReturnItemCreateSerializer(serializers.Serializer):
    material_id = serializers.IntegerField()
    qty_returned = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0.0001)
    reason = serializers.CharField(max_length=300, required=False, allow_blank=True)

class ReturnOrderCreateSerializer(serializers.Serializer):
    supplier_id = serializers.IntegerField()
    receipt_id = serializers.IntegerField(required=False, allow_null=True)
    items = ReturnItemCreateSerializer(many=True, min_length=1)


class IssueItemCreateSerializer(serializers.Serializer):
    material_id = serializers.IntegerField()
    qty_issued = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0.0001)

class IssueCreateSerializer(serializers.Serializer):
    pr_id = serializers.IntegerField(required=False, allow_null=True)
    branch_id = serializers.IntegerField()
    dept_id = serializers.IntegerField(required=False, allow_null=True)
    receiver_id = serializers.IntegerField()
    items = IssueItemCreateSerializer(many=True, min_length=1)

class StockIssueItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = StockIssueItem
        fields = ["issue_item_id", "material_id", "qty_issued", "quality_rating"]

class StockIssueSerializer(serializers.ModelSerializer):
    warehouse_keeper_name = serializers.CharField(source="warehouse_keeper.full_name", read_only=True)
    receiver_name = serializers.CharField(source="receiver.full_name", read_only=True)
    items = StockIssueItemSerializer(many=True, read_only=True)

    class Meta:
        model = StockIssue
        fields = [
            "issue_id", "issue_code", "pr_id", "dept_id", 
            "warehouse_keeper_name", "receiver_name", "issued_at", "items"
        ]
