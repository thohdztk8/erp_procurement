from django.contrib import admin

from .models import (
    ApprovalWorkflow, ApprovalWorkflowStep, EmailTemplate,
    Material, MaterialCategory, Supplier, SupplierContractPrice, SystemConfig,
)


@admin.register(MaterialCategory)
class MaterialCategoryAdmin(admin.ModelAdmin):
    list_display = ["category_code", "category_name", "is_active"]
    search_fields = ["category_code", "category_name"]


@admin.register(Material)
class MaterialAdmin(admin.ModelAdmin):
    list_display = ["material_code", "material_name", "category", "uom", "is_active"]
    list_filter = ["category", "is_active", "is_other"]
    search_fields = ["material_code", "material_name"]


@admin.register(Supplier)
class SupplierAdmin(admin.ModelAdmin):
    list_display = ["supplier_code", "supplier_name", "contact_email", "rating_score", "is_active"]
    list_filter = ["is_active"]
    search_fields = ["supplier_code", "supplier_name", "tax_code"]


@admin.register(SupplierContractPrice)
class SupplierContractPriceAdmin(admin.ModelAdmin):
    list_display = ["supplier", "material", "contract_unit_price", "valid_from", "valid_to"]
    list_filter = ["supplier"]


class ApprovalWorkflowStepInline(admin.TabularInline):
    model = ApprovalWorkflowStep
    extra = 1
    ordering = ["step_sequence"]


@admin.register(ApprovalWorkflow)
class ApprovalWorkflowAdmin(admin.ModelAdmin):
    list_display = ["workflow_name", "object_type", "min_amount", "max_amount", "is_active"]
    list_filter = ["object_type", "is_active"]
    inlines = [ApprovalWorkflowStepInline]


@admin.register(SystemConfig)
class SystemConfigAdmin(admin.ModelAdmin):
    list_display = ["config_key", "config_value_json", "updated_at"]
    search_fields = ["config_key"]


@admin.register(EmailTemplate)
class EmailTemplateAdmin(admin.ModelAdmin):
    list_display = ["template_code", "subject", "is_active", "updated_at"]
    search_fields = ["template_code"]
