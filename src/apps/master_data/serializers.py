from rest_framework import serializers

from .models import (
    ApprovalWorkflow, ApprovalWorkflowStep,
    Material, MaterialCategory,
    Supplier, SupplierContractPrice,
    SystemConfig,
)


class MaterialCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = MaterialCategory
        fields = ["category_id", "category_code", "category_name", "is_active"]


class MaterialSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source="category.category_name", read_only=True)

    class Meta:
        model = Material
        fields = [
            "material_id", "material_code", "material_name",
            "category_id", "category_name", "uom",
            "min_stock_level", "description", "is_other", "is_active",
        ]


class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = [
            "supplier_id", "supplier_code", "supplier_name",
            "tax_code", "contact_name", "contact_email",
            "contact_phone", "address", "rating_score", "is_active",
        ]


class SupplierContractPriceSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupplierContractPrice
        fields = [
            "contract_price_id", "supplier_id", "material_id",
            "contract_unit_price", "valid_from", "valid_to",
        ]

    def validate(self, attrs):
        if attrs.get("valid_to") and attrs.get("valid_from"):
            if attrs["valid_to"] < attrs["valid_from"]:
                raise serializers.ValidationError(
                    {"valid_to": "valid_to không được nhỏ hơn valid_from."}
                )
        return attrs


class ApprovalWorkflowStepSerializer(serializers.ModelSerializer):
    role_code = serializers.CharField(source="role.role_code", read_only=True)

    class Meta:
        model = ApprovalWorkflowStep
        fields = ["step_id", "step_sequence", "role_id", "role_code"]


class ApprovalWorkflowSerializer(serializers.ModelSerializer):
    steps = ApprovalWorkflowStepSerializer(many=True, read_only=True)

    class Meta:
        model = ApprovalWorkflow
        fields = [
            "workflow_id", "workflow_name", "object_type",
            "min_amount", "max_amount", "dept_id", "is_active", "steps",
        ]


class SystemConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = SystemConfig
        fields = ["config_id", "config_key", "config_value", "description", "updated_at"]
