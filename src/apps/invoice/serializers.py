from rest_framework import serializers

from .models import (
    CreditNote, DebitNote, Invoice, InvoiceItem,
    PaymentRequest, ThreeWayMatchingResult,
)


class InvoiceItemCreateSerializer(serializers.Serializer):
    ipo_item_id = serializers.IntegerField()
    qty_invoice = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0.0001)
    price_invoice = serializers.DecimalField(max_digits=18, decimal_places=2, min_value=0)


class InvoiceCreateSerializer(serializers.Serializer):
    invoice_code = serializers.CharField(max_length=50)
    ipo_id = serializers.IntegerField()
    supplier_id = serializers.IntegerField()
    invoice_date = serializers.DateField()
    total_invoice_amount = serializers.DecimalField(max_digits=18, decimal_places=2, min_value=0)
    tax_amount = serializers.DecimalField(max_digits=18, decimal_places=2, default=0, min_value=0)
    items = InvoiceItemCreateSerializer(many=True, min_length=1)

    def validate_invoice_code(self, value):
        if Invoice.objects.filter(invoice_code=value).exists():
            raise serializers.ValidationError("Mã hóa đơn đã tồn tại.")
        return value

    def validate_ipo_id(self, value):
        from apps.ipo.models import IPO
        try:
            IPO.objects.get(ipo_id=value, ipo_status="APPROVED", is_latest=True)
        except IPO.DoesNotExist:
            raise serializers.ValidationError("IPO không tồn tại hoặc chưa được phê duyệt.")
        return value


class InvoiceItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = InvoiceItem
        fields = ["invoice_item_id", "ipo_item_id", "qty_invoice", "price_invoice"]


class InvoiceListSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source="supplier.supplier_name", read_only=True)

    class Meta:
        model = Invoice
        fields = [
            "invoice_id", "invoice_code", "invoice_status",
            "total_invoice_amount", "tax_amount", "supplier_name",
            "invoice_date", "created_at",
        ]


class InvoiceDetailSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source="supplier.supplier_name", read_only=True)
    items = InvoiceItemSerializer(many=True, read_only=True)

    class Meta:
        model = Invoice
        fields = [
            "invoice_id", "invoice_code", "invoice_status",
            "total_invoice_amount", "tax_amount",
            "supplier_name", "invoice_date", "items", "created_at",
        ]


class ThreeWayMatchingSerializer(serializers.ModelSerializer):
    class Meta:
        model = ThreeWayMatchingResult
        fields = [
            "matching_id", "qty_invoice", "qty_received_passed", "qty_diff",
            "price_invoice", "price_ipo", "price_diff",
            "is_error", "is_overridden", "override_note", "matched_at",
        ]


class OverrideSerializer(serializers.Serializer):
    override_note = serializers.CharField(min_length=10, max_length=500)


class PaymentRequestSerializer(serializers.ModelSerializer):
    invoice_code = serializers.CharField(source="invoice.invoice_code", read_only=True)
    requested_by_name = serializers.CharField(source="requested_by.full_name", read_only=True)

    class Meta:
        model = PaymentRequest
        fields = [
            "payment_id", "invoice_code", "amount",
            "payment_status", "requested_by_name",
            "payment_date", "note", "created_at",
        ]


class PaymentApproveSerializer(serializers.Serializer):
    payment_id = serializers.IntegerField()
    action = serializers.ChoiceField(choices=["APPROVE", "REJECT"])
    note = serializers.CharField(required=False, allow_blank=True, max_length=500)
