"""
Module 8: Invoice, 3-Way Matching & Payment.
Bảng DB thực tế:
  Invoices              — FIX: invoice_number, amount_before_tax/tax_amount/total_amount, matching_status
  InvoiceMatchingResults— FIX: tên bảng, bỏ OneToOne, thêm ipo_item_id, log_details_json
  PaymentRequests       — FIX: payment_req_id, payment_req_code, applicant_user_id, requested_amount,
                               payment_deadline, req_status
  CreditNotes           — FIX: credit_note_id/code/number, tách amount, thêm credit_date/pdf/applied_status
  DebitNotes            — FIX: tương tự CreditNotes
  SupplierEvaluations   — FIX: tách period thành period_type/value/start/end, thêm rank/is_finalized
  SupplierEvaluationCriteria — FIX: thêm criteria_code, raw_score, weighted_score, data_source_json
"""
from django.db import models

from apps.authentication.models import User
from apps.ipo.models import IPO, IPOItem
from apps.master_data.models import Supplier
from apps.warehouse.models import StockReceiptItem


class Invoice(models.Model):
    STATUS_CHOICES = [
        ("PENDING", "Chờ đối soát"),
        ("MATCHED", "Khớp"),
        ("MISMATCHED", "Sai lệch"),
        ("PAID", "Đã thanh toán"),
    ]

    invoice_id = models.AutoField(primary_key=True)
    # FIX: invoice_number thay cho invoice_code
    invoice_number = models.CharField(max_length=50)
    invoice_date = models.DateTimeField()
    supplier = models.ForeignKey(
        Supplier, on_delete=models.PROTECT, db_column="supplier_id"
    )
    ipo = models.ForeignKey(
        IPO, on_delete=models.PROTECT, db_column="ipo_id", related_name="invoices"
    )
    # FIX: tách amount thành 3 trường
    amount_before_tax = models.DecimalField(max_digits=18, decimal_places=2)
    tax_amount = models.DecimalField(max_digits=18, decimal_places=2)
    total_amount = models.DecimalField(max_digits=18, decimal_places=2)
    invoice_pdf_path = models.CharField(max_length=500, null=True, blank=True)
    # FIX: matching_status thay cho invoice_status
    matching_status = models.CharField(max_length=30, choices=STATUS_CHOICES, default="PENDING")
    is_overridden = models.BooleanField(default=False)
    override_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        db_column="override_by_user_id", related_name="overridden_invoices"
    )
    override_note = models.CharField(max_length=500, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "Invoices"
        unique_together = (("invoice_number", "supplier"),)

    def __str__(self):
        return self.invoice_number

    # Compatibility property cho code cũ dùng invoice_code / invoice_status / total_invoice_amount
    @property
    def invoice_code(self):
        return self.invoice_number

    @property
    def invoice_status(self):
        return self.matching_status

    @invoice_status.setter
    def invoice_status(self, value):
        self.matching_status = value

    @property
    def total_invoice_amount(self):
        return self.total_amount


class InvoiceItem(models.Model):
    invoice_item_id = models.AutoField(primary_key=True)
    invoice = models.ForeignKey(
        Invoice, on_delete=models.CASCADE, db_column="invoice_id", related_name="items"
    )
    ipo_item = models.ForeignKey(
        IPOItem, on_delete=models.PROTECT, db_column="ipo_item_id"
    )
    qty_invoice = models.DecimalField(max_digits=18, decimal_places=4)
    price_invoice = models.DecimalField(max_digits=18, decimal_places=2)

    class Meta:
        db_table = "InvoiceItems"


class InvoiceMatchingResult(models.Model):
    # FIX: tên bảng InvoiceMatchingResults, bỏ OneToOne, thêm ipo_item_id + log_details_json
    matching_id = models.AutoField(primary_key=True)
    invoice = models.ForeignKey(
        Invoice, on_delete=models.CASCADE,
        db_column="invoice_id", related_name="matching_results"
    )
    ipo_item = models.ForeignKey(
        IPOItem, on_delete=models.PROTECT, db_column="ipo_item_id"
    )
    receipt_item = models.ForeignKey(
        StockReceiptItem, on_delete=models.PROTECT, db_column="receipt_item_id"
    )
    qty_invoice = models.DecimalField(max_digits=18, decimal_places=4)
    qty_received_passed = models.DecimalField(max_digits=18, decimal_places=4)
    price_invoice = models.DecimalField(max_digits=18, decimal_places=2)
    price_ipo = models.DecimalField(max_digits=18, decimal_places=2)
    qty_diff = models.DecimalField(max_digits=18, decimal_places=4)
    price_diff = models.DecimalField(max_digits=18, decimal_places=2)
    is_error = models.BooleanField(default=False)
    log_details_json = models.TextField(null=True, blank=True)

    class Meta:
        db_table = "InvoiceMatchingResults"

# Backwards-compat alias
ThreeWayMatchingResult = InvoiceMatchingResult


class PaymentRequest(models.Model):
    STATUS_CHOICES = [
        ("PENDING", "Chờ duyệt"),
        ("APPROVED", "Đã duyệt"),
        ("PAID", "Đã thanh toán"),
        ("REJECTED", "Từ chối"),
    ]

    # FIX: payment_req_id, payment_req_code, applicant_user_id, requested_amount,
    #      payment_deadline, req_status
    payment_req_id = models.AutoField(primary_key=True)
    payment_req_code = models.CharField(max_length=30, unique=True)
    invoice = models.OneToOneField(
        Invoice, on_delete=models.PROTECT, db_column="invoice_id", related_name="payment"
    )
    applicant = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="applicant_user_id"
    )
    requested_amount = models.DecimalField(max_digits=18, decimal_places=2)
    payment_deadline = models.DateTimeField()
    req_status = models.CharField(max_length=30, choices=STATUS_CHOICES, default="PENDING")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "PaymentRequests"

    # Compatibility properties
    @property
    def payment_id(self):
        return self.payment_req_id

    @property
    def amount(self):
        return self.requested_amount

    @property
    def payment_status(self):
        return self.req_status

    @payment_status.setter
    def payment_status(self, value):
        self.req_status = value

    @property
    def requested_by(self):
        return self.applicant


class CreditNote(models.Model):
    APPLIED_STATUS_CHOICES = [
        ("PENDING", "Chờ"),
        ("APPLIED", "Đã áp dụng"),
        ("REFUNDED", "Đã hoàn tiền"),
    ]

    # FIX: credit_note_id, credit_note_code, credit_note_number, tách amount,
    #      credit_date, credit_pdf_path, applied_status, applied_to_payment_id, return_id
    credit_note_id = models.AutoField(primary_key=True)
    credit_note_code = models.CharField(max_length=30, unique=True)
    credit_note_number = models.CharField(max_length=50)
    supplier = models.ForeignKey(Supplier, on_delete=models.PROTECT, db_column="supplier_id")
    invoice = models.ForeignKey(
        Invoice, on_delete=models.PROTECT, db_column="invoice_id", related_name="credit_notes"
    )
    return_order = models.ForeignKey(
        "warehouse.ReturnOrder", on_delete=models.SET_NULL,
        null=True, blank=True, db_column="return_id"
    )
    credit_amount_before_tax = models.DecimalField(max_digits=18, decimal_places=2)
    credit_tax_amount = models.DecimalField(max_digits=18, decimal_places=2)
    credit_total_amount = models.DecimalField(max_digits=18, decimal_places=2)
    credit_date = models.DateTimeField()
    reason = models.CharField(max_length=500)
    credit_pdf_path = models.CharField(max_length=500, null=True, blank=True)
    applied_status = models.CharField(max_length=30, choices=APPLIED_STATUS_CHOICES, default="PENDING")
    applied_to_payment = models.ForeignKey(
        PaymentRequest, on_delete=models.SET_NULL,
        null=True, blank=True, db_column="applied_to_payment_id"
    )
    # created_by = models.ForeignKey(
    #     User, on_delete=models.PROTECT, db_column="created_by_user_id"
    # )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "CreditNotes"


class DebitNote(models.Model):
    APPLIED_STATUS_CHOICES = [
        ("PENDING", "Chờ"),
        ("APPLIED", "Đã áp dụng"),
    ]

    # FIX: debit_note_id, debit_note_code, debit_note_number, debit_amount, debit_date,
    #      debit_pdf_path, applied_status, applied_to_payment_id
    debit_note_id = models.AutoField(primary_key=True)
    debit_note_code = models.CharField(max_length=30, unique=True)
    debit_note_number = models.CharField(max_length=50)
    supplier = models.ForeignKey(Supplier, on_delete=models.PROTECT, db_column="supplier_id")
    invoice = models.ForeignKey(
        Invoice, on_delete=models.PROTECT, db_column="invoice_id", related_name="debit_notes"
    )
    debit_amount = models.DecimalField(max_digits=18, decimal_places=2)
    debit_date = models.DateTimeField()
    reason = models.CharField(max_length=500)
    debit_pdf_path = models.CharField(max_length=500, null=True, blank=True)
    applied_status = models.CharField(max_length=30, choices=APPLIED_STATUS_CHOICES, default="PENDING")
    applied_to_payment = models.ForeignKey(
        PaymentRequest, on_delete=models.SET_NULL,
        null=True, blank=True, db_column="applied_to_payment_id"
    )
    # created_by = models.ForeignKey(
    #     User, on_delete=models.PROTECT, db_column="created_by_user_id"
    # )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "DebitNotes"


class SupplierEvaluation(models.Model):
    PERIOD_TYPE_CHOICES = [
        ("MONTH", "Tháng"),
        ("QUARTER", "Quý"),
        ("YEAR", "Năm"),
    ]
    RANK_CHOICES = [
        ("GOLD", "Vàng"),
        ("SILVER", "Bạc"),
        ("BRONZE", "Đồng"),
        ("WARNING", "Cảnh báo"),
    ]

    evaluation_id = models.AutoField(primary_key=True)
    supplier = models.ForeignKey(Supplier, on_delete=models.PROTECT, db_column="supplier_id")
    # FIX: tách period thành period_type + period_value + period_start_date + period_end_date
    period_type = models.CharField(max_length=20, choices=PERIOD_TYPE_CHOICES)
    period_value = models.CharField(max_length=20)         # VD: "2026-Q1", "2026-01"
    period_start_date = models.DateTimeField()
    period_end_date = models.DateTimeField()
    total_score = models.DecimalField(max_digits=5, decimal_places=2)
    rank = models.CharField(max_length=20, choices=RANK_CHOICES)
    subjective_comment = models.CharField(max_length=1000, null=True, blank=True)
    is_finalized = models.BooleanField(default=False)
    evaluator = models.ForeignKey(
        User, on_delete=models.PROTECT, db_column="evaluator_user_id"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    finalized_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "SupplierEvaluations"
        unique_together = (("supplier", "period_type", "period_value"),)


class SupplierEvaluationCriteria(models.Model):
    # FIX: thêm criteria_code (UNIQUE per eval), raw_score, weighted_score, data_source_json
    criteria_id = models.AutoField(primary_key=True)
    evaluation = models.ForeignKey(
        SupplierEvaluation, on_delete=models.CASCADE,
        db_column="evaluation_id", related_name="criteria"
    )
    criteria_code = models.CharField(max_length=50)
    criteria_name = models.CharField(max_length=150)
    raw_score = models.DecimalField(max_digits=5, decimal_places=2)
    weight = models.DecimalField(max_digits=5, decimal_places=4)
    weighted_score = models.DecimalField(max_digits=7, decimal_places=4)
    data_source_json = models.TextField(null=True, blank=True)
    notes = models.CharField(max_length=500, null=True, blank=True)

    class Meta:
        db_table = "SupplierEvaluationCriteria"
        unique_together = (("evaluation", "criteria_code"),)
