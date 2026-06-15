from rest_framework import serializers

from .models import (
    CreditNote, DebitNote, Invoice, InvoiceItem,
    PaymentRequest, ThreeWayMatchingResult, InvoiceMatchingResult,
    SupplierEvaluation
)


class InvoiceItemCreateSerializer(serializers.Serializer):
    ipo_item_id = serializers.IntegerField()
    qty_invoice = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0.0001)
    price_invoice = serializers.DecimalField(max_digits=18, decimal_places=2, min_value=0)


class InvoiceCreateSerializer(serializers.Serializer):
    invoice_number = serializers.CharField(max_length=50)
    ipo_id = serializers.IntegerField()
    supplier_id = serializers.IntegerField()
    invoice_date = serializers.DateTimeField()
    amount_before_tax = serializers.DecimalField(max_digits=18, decimal_places=2, min_value=0)
    tax_amount = serializers.DecimalField(max_digits=18, decimal_places=2, default=0, min_value=0)
    total_amount = serializers.DecimalField(max_digits=18, decimal_places=2, min_value=0)
    invoice_pdf_path = serializers.CharField(max_length=500, required=False, allow_blank=True)
    items = InvoiceItemCreateSerializer(many=True, min_length=1)

    def validate_invoice_number(self, value):
        if Invoice.objects.filter(invoice_number=value).exists():
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
            "invoice_id", "invoice_number", "matching_status",
            "amount_before_tax", "tax_amount", "total_amount", "supplier_name",
            "invoice_date", "created_at",
        ]


class InvoiceDetailSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source="supplier.supplier_name", read_only=True)
    items = InvoiceItemSerializer(many=True, read_only=True)

    class Meta:
        model = Invoice
        fields = [
            "invoice_id", "invoice_number", "matching_status",
            "amount_before_tax", "tax_amount", "total_amount",
            "supplier_name", "invoice_date", "items", "created_at",
        ]


class ThreeWayMatchingSerializer(serializers.ModelSerializer):
    class Meta:
        model = InvoiceMatchingResult
        fields = [
            "matching_id", "qty_invoice", "qty_received_passed", "qty_diff",
            "price_invoice", "price_ipo", "price_diff",
            "is_error", "log_details_json",
        ]


class OverrideSerializer(serializers.Serializer):
    override_note = serializers.CharField(min_length=10, max_length=500)


class PaymentRequestSerializer(serializers.ModelSerializer):
    invoice_number = serializers.CharField(source="invoice.invoice_number", read_only=True)
    applicant_name = serializers.CharField(source="applicant.full_name", read_only=True)

    class Meta:
        model = PaymentRequest
        fields = [
            "payment_req_id", "payment_req_code", "invoice_number", "requested_amount",
            "req_status", "applicant_name",
            "payment_deadline", "created_at",
        ]


class PaymentApproveSerializer(serializers.Serializer):
    payment_id = serializers.IntegerField()
    action = serializers.ChoiceField(choices=["APPROVE", "REJECT"])
    note = serializers.CharField(required=False, allow_blank=True, max_length=500)

class SupplierEvaluationSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupplierEvaluation
        fields = "__all__"

class SupplierEvaluationCreateSerializer(serializers.Serializer):
    supplier_id = serializers.IntegerField()
    period_type = serializers.ChoiceField(choices=["MONTH", "QUARTER", "YEAR"])
    period_value = serializers.CharField(max_length=20)
    period_start_date = serializers.DateTimeField()
    period_end_date = serializers.DateTimeField()
