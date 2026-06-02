from rest_framework import serializers

from .models import DocumentApprovalProgress, PRItem, PRStatusHistory, PurchaseRequisition
from .validators import validate_material_cross_exclusion, validate_urgent_fields


class PRItemCreateSerializer(serializers.Serializer):
    material_id = serializers.IntegerField(required=False, allow_null=True)
    material_name_other = serializers.CharField(
        required=False, allow_blank=True, allow_null=True, max_length=300
    )
    qty_requested = serializers.DecimalField(max_digits=18, decimal_places=4, min_value=0.0001)
    estimated_unit_price = serializers.DecimalField(
        max_digits=18, decimal_places=2, default=0, min_value=0
    )
    required_deadline = serializers.DateTimeField()

    def validate(self, attrs):
        validate_material_cross_exclusion(
            attrs.get("material_id"),
            attrs.get("material_name_other"),
        )
        return attrs


class PRCreateSerializer(serializers.Serializer):
    priority_level = serializers.ChoiceField(choices=["NORMAL", "URGENT"], default="NORMAL")
    urgent_reason = serializers.CharField(
        required=False, allow_blank=True, allow_null=True, max_length=500
    )
    urgency_impact = serializers.CharField(
        required=False, allow_blank=True, allow_null=True, max_length=500
    )
    items = PRItemCreateSerializer(many=True, min_length=1)

    def validate(self, attrs):
        validate_urgent_fields(
            attrs.get("priority_level", "NORMAL"),
            attrs.get("urgent_reason"),
            attrs.get("urgency_impact"),
        )
        return attrs


class PRItemSerializer(serializers.ModelSerializer):
    material_code = serializers.CharField(source="material.material_code", read_only=True)
    material_name = serializers.SerializerMethodField()

    class Meta:
        model = PRItem
        fields = [
            "pr_item_id", "material_id", "material_code",
            "material_name", "material_name_other",
            "qty_requested", "qty_ordered", "qty_received",
            "estimated_unit_price", "required_deadline", "item_status",
        ]

    def get_material_name(self, obj):
        if obj.material_id:
            return obj.material.material_name
        return obj.material_name_other


class PRListSerializer(serializers.ModelSerializer):
    requester_name = serializers.CharField(source="requester.full_name", read_only=True)
    dept_name = serializers.CharField(source="dept.dept_name", read_only=True)
    branch_name = serializers.CharField(source="branch.branch_name", read_only=True)
    item_count = serializers.SerializerMethodField()

    class Meta:
        model = PurchaseRequisition
        fields = [
            "pr_id", "pr_code", "priority_level", "pr_status",
            "total_estimated_amount", "requester_name",
            "dept_name", "branch_name", "item_count", "created_at",
        ]

    def get_item_count(self, obj):
        return obj.items.count()


class PRDetailSerializer(serializers.ModelSerializer):
    requester_name = serializers.CharField(source="requester.full_name", read_only=True)
    dept_name = serializers.CharField(source="dept.dept_name", read_only=True)
    branch_name = serializers.CharField(source="branch.branch_name", read_only=True)
    items = PRItemSerializer(many=True, read_only=True)

    class Meta:
        model = PurchaseRequisition
        fields = [
            "pr_id", "pr_code", "priority_level", "pr_status",
            "urgent_reason", "urgency_impact",
            "total_estimated_amount", "requester_name",
            "dept_name", "branch_name", "items",
            "created_at", "updated_at",
        ]


class PRApproveSerializer(serializers.Serializer):
    pr_id = serializers.IntegerField()
    action = serializers.ChoiceField(choices=["APPROVE", "REJECT"])
    comment = serializers.CharField(required=False, allow_blank=True, max_length=500)

    def validate(self, attrs):
        if attrs["action"] == "REJECT" and not attrs.get("comment", "").strip():
            raise serializers.ValidationError(
                {"comment": "Bắt buộc nhập lý do khi từ chối."}
            )
        return attrs


class ApprovalProgressSerializer(serializers.ModelSerializer):
    approver_name = serializers.CharField(source="approver.full_name", read_only=True)

    class Meta:
        model = DocumentApprovalProgress
        fields = [
            "progress_id", "step_sequence", "approver_name",
            "approval_status", "comment", "action_date",
        ]
