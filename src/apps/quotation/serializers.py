from rest_framework import serializers

from .models import Quotation, QuotationItem, QuotationRequest, QuotationToken, QuotationVersion


class InviteQuotationSerializer(serializers.Serializer):
    order_id = serializers.IntegerField()
    supplier_ids = serializers.ListField(child=serializers.IntegerField(), min_length=1)
    deadline_submission = serializers.DateTimeField()

    def validate_order_id(self, value):
        from apps.cart_order.models import Order
        try:
            order = Order.objects.get(order_id=value)
        except Order.DoesNotExist:
            raise serializers.ValidationError("Không tìm thấy đơn hàng.")
        if order.order_status not in ["DRAFT", "QUOTING"]:
            raise serializers.ValidationError("Đơn hàng không ở trạng thái phù hợp để mời báo giá.")
        return value


class QuotationItemSubmitSerializer(serializers.Serializer):
    order_item_id = serializers.IntegerField()
    quoted_unit_price = serializers.DecimalField(max_digits=18, decimal_places=2, min_value=0)
    supplier_note = serializers.CharField(required=False, allow_blank=True, max_length=300)


class VendorPortalSubmitSerializer(serializers.Serializer):
    """Endpoint public — NCC dùng token thay vì JWT"""
    token = serializers.CharField(max_length=128)
    delivery_lead_time_days = serializers.IntegerField(min_value=1)
    payment_terms_note = serializers.CharField(required=False, allow_blank=True, max_length=200)
    items = QuotationItemSubmitSerializer(many=True, min_length=1)

    def validate_token(self, value):
        from django.utils import timezone
        try:
            token_obj = QuotationToken.objects.select_related("q_request").get(token=value)
        except QuotationToken.DoesNotExist:
            raise serializers.ValidationError("Token không hợp lệ.")
        if token_obj.is_used:
            raise serializers.ValidationError("Token đã được sử dụng.")
        if token_obj.expires_at < timezone.now():
            raise serializers.ValidationError("Token đã hết hạn.")
        return value


class QuotationItemSerializer(serializers.ModelSerializer):
    material_name = serializers.SerializerMethodField()

    class Meta:
        model = QuotationItem
        fields = ["q_item_id", "order_item_id", "material_name", "quoted_unit_price", "supplier_note"]

    def get_material_name(self, obj):
        oi = obj.order_item
        return oi.material.material_name if oi.material_id else oi.material_name_other


class QuotationSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source="supplier.supplier_name", read_only=True)
    items = QuotationItemSerializer(many=True, read_only=True)

    class Meta:
        model = Quotation
        fields = [
            "quotation_id", "supplier_name", "submitted_at",
            "delivery_lead_time_days", "payment_terms_note",
            "total_quote_amount", "is_selected", "items",
        ]


class QuotationVersionSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuotationVersion
        fields = [
            "version_id", "version_number", "is_current",
            "snapshot_total_amount", "snapshot_lead_time_days",
            "submitted_at", "change_summary",
        ]


class SelectQuotationSerializer(serializers.Serializer):
    quotation_id = serializers.IntegerField()
