from django.contrib import admin

from .models import DocumentApprovalProgress, PRItem, PRStatusHistory, PurchaseRequisition


class PRItemInline(admin.TabularInline):
    model = PRItem
    extra = 0
    readonly_fields = ["qty_ordered", "qty_received", "item_status"]


@admin.register(PurchaseRequisition)
class PurchaseRequisitionAdmin(admin.ModelAdmin):
    list_display = ["pr_code", "priority_level", "pr_status", "requester", "dept", "total_estimated_amount", "created_at"]
    list_filter = ["pr_status", "priority_level", "branch"]
    search_fields = ["pr_code", "requester__username"]
    readonly_fields = ["pr_code", "total_estimated_amount", "created_at", "updated_at"]
    inlines = [PRItemInline]


@admin.register(DocumentApprovalProgress)
class DocumentApprovalProgressAdmin(admin.ModelAdmin):
    list_display = ["document_type", "document_id", "step_sequence", "approver", "approval_status", "action_date"]
    list_filter = ["document_type", "approval_status"]


@admin.register(PRStatusHistory)
class PRStatusHistoryAdmin(admin.ModelAdmin):
    list_display = ["pr", "from_status", "to_status", "changed_by", "changed_at"]
    readonly_fields = ["pr", "from_status", "to_status", "changed_by", "changed_at"]
