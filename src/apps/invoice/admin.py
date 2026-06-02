from django.contrib import admin

from .models import (
    CreditNote, DebitNote, Invoice, InvoiceItem,
    InvoiceMatchingResult, PaymentRequest,
    SupplierEvaluation, SupplierEvaluationCriteria,
)


class InvoiceItemInline(admin.TabularInline):
    model = InvoiceItem
    extra = 0


class InvoiceMatchingInline(admin.TabularInline):
    model = InvoiceMatchingResult
    extra = 0
    readonly_fields = ["qty_diff", "price_diff", "is_error"]


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ["invoice_number", "supplier", "matching_status", "total_amount", "invoice_date"]
    list_filter = ["matching_status", "supplier"]
    search_fields = ["invoice_number"]
    readonly_fields = ["created_at"]
    inlines = [InvoiceItemInline, InvoiceMatchingInline]


@admin.register(PaymentRequest)
class PaymentRequestAdmin(admin.ModelAdmin):
    list_display = ["payment_req_id", "payment_req_code", "invoice", "requested_amount", "req_status"]
    list_filter = ["req_status"]


@admin.register(CreditNote)
class CreditNoteAdmin(admin.ModelAdmin):
    list_display = ["credit_note_code", "invoice", "supplier", "credit_total_amount", "applied_status", "created_at"]
    list_filter = ["applied_status"]


@admin.register(DebitNote)
class DebitNoteAdmin(admin.ModelAdmin):
    list_display = ["debit_note_code", "invoice", "supplier", "debit_amount", "applied_status", "created_at"]
    list_filter = ["applied_status"]


class SupplierEvaluationCriteriaInline(admin.TabularInline):
    model = SupplierEvaluationCriteria
    extra = 0


@admin.register(SupplierEvaluation)
class SupplierEvaluationAdmin(admin.ModelAdmin):
    list_display = ["supplier", "period_type", "period_value", "total_score", "rank", "is_finalized", "created_at"]
    list_filter = ["period_type", "rank", "is_finalized"]
    inlines = [SupplierEvaluationCriteriaInline]
