from django.contrib import admin

from .models import IPO, IPOItem


class IPOItemInline(admin.TabularInline):
    model = IPOItem
    extra = 0
    readonly_fields = ["total_price"]


@admin.register(IPO)
class IPOAdmin(admin.ModelAdmin):
    list_display = ["ipo_code", "version", "is_latest", "ipo_status", "supplier", "total_amount", "created_at"]
    list_filter = ["ipo_status", "is_latest"]
    search_fields = ["ipo_code", "supplier__supplier_name"]
    readonly_fields = ["ipo_code", "version", "is_latest", "created_at"]
    inlines = [IPOItemInline]
