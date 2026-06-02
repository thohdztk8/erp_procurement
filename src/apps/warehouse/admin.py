from django.contrib import admin

from .models import Inventory, ReturnOrder, ReturnOrderItem, StockIssue, StockIssueItem, StockReceipt, StockReceiptItem


class ReceiptItemInline(admin.TabularInline):
    model = StockReceiptItem
    extra = 0
    readonly_fields = ["qty_received", "qty_passed", "qty_failed"]


@admin.register(StockReceipt)
class StockReceiptAdmin(admin.ModelAdmin):
    list_display = ["receipt_code", "ipo", "warehouse_keeper", "received_at"]
    search_fields = ["receipt_code"]
    inlines = [ReceiptItemInline]


@admin.register(Inventory)
class InventoryAdmin(admin.ModelAdmin):
    list_display = ["branch", "material", "qty_on_hand", "qty_available", "qty_quarantine", "last_updated_at"]
    search_fields = ["material__material_code", "material__material_name"]
    list_filter = ["branch"]
    readonly_fields = ["last_updated_at"]


class StockIssueItemInline(admin.TabularInline):
    model = StockIssueItem
    extra = 0


@admin.register(StockIssue)
class StockIssueAdmin(admin.ModelAdmin):
    list_display = ["issue_code", "dept", "warehouse_keeper", "receiver", "issued_at"]
    search_fields = ["issue_code"]
    inlines = [StockIssueItemInline]


class ReturnOrderItemInline(admin.TabularInline):
    model = ReturnOrderItem
    extra = 0


@admin.register(ReturnOrder)
class ReturnOrderAdmin(admin.ModelAdmin):
    list_display = ["return_code", "supplier", "receipt", "return_status", "created_at"]
    list_filter = ["return_status"]
    inlines = [ReturnOrderItemInline]
