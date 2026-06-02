"""
Module 2: Master Data — Danh mục gốc dùng chung toàn hệ thống.
Bảng: MaterialCategories, Materials, Suppliers, SupplierContractPrices,
      ApprovalWorkflows, ApprovalWorkflowSteps, SystemConfigs, EmailTemplates
"""
from django.db import models

from apps.authentication.models import Branch, Department, Role


class MaterialCategory(models.Model):
    category_id = models.AutoField(primary_key=True)
    category_code = models.CharField(max_length=20, unique=True)
    category_name = models.CharField(max_length=150)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "MaterialCategories"

    def __str__(self):
        return self.category_name


class Material(models.Model):
    material_id = models.AutoField(primary_key=True)
    material_code = models.CharField(max_length=50, unique=True)
    material_name = models.CharField(max_length=300)
    category = models.ForeignKey(
        MaterialCategory, on_delete=models.PROTECT, db_column="category_id"
    )
    uom = models.CharField(max_length=30)                   # Đơn vị tính
    min_stock_level = models.DecimalField(max_digits=18, decimal_places=4, default=0)
    description = models.CharField(max_length=500, null=True, blank=True)
    is_other = models.BooleanField(default=False)           # 1 = hàng ngoài danh mục
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "Materials"

    def __str__(self):
        return self.material_name


class Supplier(models.Model):
    supplier_id = models.AutoField(primary_key=True)
    supplier_code = models.CharField(max_length=30, unique=True)
    supplier_name = models.CharField(max_length=250)
    tax_code = models.CharField(max_length=20, null=True, blank=True)
    contact_name = models.CharField(max_length=100, null=True, blank=True)
    contact_email = models.EmailField(max_length=100)
    contact_phone = models.CharField(max_length=20, null=True, blank=True)
    address = models.CharField(max_length=500, null=True, blank=True)
    rating_score = models.DecimalField(max_digits=5, decimal_places=2, default=5.00)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "Suppliers"

    def __str__(self):
        return self.supplier_name


class SupplierContractPrice(models.Model):
    contract_price_id = models.AutoField(primary_key=True)
    supplier = models.ForeignKey(Supplier, on_delete=models.PROTECT, db_column="supplier_id")
    material = models.ForeignKey(Material, on_delete=models.PROTECT, db_column="material_id")
    contract_unit_price = models.DecimalField(max_digits=18, decimal_places=2)
    valid_from = models.DateTimeField()
    valid_to = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "SupplierContractPrices"

    def clean(self):
        from django.core.exceptions import ValidationError
        if self.valid_to < self.valid_from:
            raise ValidationError("valid_to không được nhỏ hơn valid_from.")


class ApprovalWorkflow(models.Model):
    workflow_id = models.AutoField(primary_key=True)
    workflow_name = models.CharField(max_length=100)
    object_type = models.CharField(max_length=50)           # PR_NORMAL | PR_URGENT | IPO
    min_amount = models.DecimalField(max_digits=18, decimal_places=2, default=0)
    max_amount = models.DecimalField(max_digits=18, decimal_places=2, null=True, blank=True)
    dept = models.ForeignKey(
        Department, on_delete=models.SET_NULL, null=True, blank=True, db_column="dept_id"
    )
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "ApprovalWorkflows"

    def __str__(self):
        return self.workflow_name


class ApprovalWorkflowStep(models.Model):
    step_id = models.AutoField(primary_key=True)
    workflow = models.ForeignKey(
        ApprovalWorkflow, on_delete=models.CASCADE,
        db_column="workflow_id", related_name="steps"
    )
    step_sequence = models.IntegerField()
    role = models.ForeignKey(Role, on_delete=models.PROTECT, db_column="role_id")

    class Meta:
        db_table = "ApprovalWorkflowSteps"
        ordering = ["step_sequence"]


class SystemConfig(models.Model):
    config_id = models.AutoField(primary_key=True)
    config_key = models.CharField(max_length=100, unique=True)
    config_value_json = models.TextField()
    description = models.CharField(max_length=300, null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "SystemConfigs"

    def __str__(self):
        return self.config_key


class EmailTemplate(models.Model):
    template_id = models.AutoField(primary_key=True)
    template_code = models.CharField(max_length=100, unique=True)
    subject = models.CharField(max_length=300)
    body = models.TextField()
    # description = models.CharField(max_length=300, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "EmailTemplates"

    def __str__(self):
        return self.template_code
