from django.contrib import admin

from .models import Quotation, QuotationItem, QuotationRequest, QuotationToken, QuotationVersion


class QuotationItemInline(admin.TabularInline):
    model = QuotationItem
    extra = 0


class QuotationVersionInline(admin.TabularInline):
    model = QuotationVersion
    extra = 0
    readonly_fields = ["version_number", "snapshot_total_amount", "submitted_at", "is_current"]


@admin.register(QuotationRequest)
class QuotationRequestAdmin(admin.ModelAdmin):
    list_display = ["q_request_id", "order", "supplier", "deadline_submission", "sent_at"]
    list_filter = ["supplier"]


@admin.register(QuotationToken)
class QuotationTokenAdmin(admin.ModelAdmin):
    list_display = ["token_id", "q_request", "expires_at", "is_used", "used_at"]
    list_filter = ["is_used"]
    readonly_fields = ["token", "created_at"]


@admin.register(Quotation)
class QuotationAdmin(admin.ModelAdmin):
    list_display = ["quotation_id", "supplier", "total_quote_amount", "is_selected", "submitted_at"]
    list_filter = ["is_selected"]
    inlines = [QuotationItemInline, QuotationVersionInline]
