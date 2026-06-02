"""
ApprovalMatrixService: resolve ApprovalWorkflow phù hợp dựa trên
loại chứng từ, tổng tiền và phòng ban.
"""
import logging
from decimal import Decimal

from .models import ApprovalWorkflow, ApprovalWorkflowStep

logger = logging.getLogger("apps")


class ApprovalMatrixService:
    @staticmethod
    def resolve_workflow(
        object_type: str,
        total_amount: Decimal,
        dept_id: int | None = None,
    ) -> ApprovalWorkflow | None:
        """
        Tìm ApprovalWorkflow khớp với loại chứng từ và tổng tiền.
        Ưu tiên workflow riêng cho phòng ban trước, sau đó workflow toàn công ty.

        Args:
            object_type:  "PR_NORMAL" | "PR_URGENT" | "IPO"
            total_amount: Tổng giá trị chứng từ
            dept_id:      Phòng ban của người lập chứng từ

        Returns:
            ApprovalWorkflow instance hoặc None nếu không tìm thấy
        """
        qs = ApprovalWorkflow.objects.filter(
            object_type=object_type,
            is_active=True,
            min_amount__lte=total_amount,
        ).filter(
            # max_amount IS NULL hoặc max_amount >= total_amount
            models_filter_max(total_amount)
        )

        # Ưu tiên workflow của phòng ban
        if dept_id:
            dept_wf = qs.filter(dept_id=dept_id).first()
            if dept_wf:
                return dept_wf

        # Fallback về workflow toàn công ty (dept IS NULL)
        return qs.filter(dept__isnull=True).first()

    @staticmethod
    def get_approvers_for_step(workflow: ApprovalWorkflow, step_sequence: int) -> list:
        """
        Trả về danh sách User có role phù hợp tại bước phê duyệt.
        """
        from apps.authentication.models import User

        step = ApprovalWorkflowStep.objects.filter(
            workflow=workflow, step_sequence=step_sequence
        ).first()

        if not step:
            return []

        return list(
            User.objects.filter(role=step.role, is_active=True).select_related("dept")
        )


def models_filter_max(total_amount: Decimal):
    """
    Helper: Q object để lọc max_amount IS NULL hoặc max_amount >= total_amount.
    """
    from django.db.models import Q
    return Q(max_amount__isnull=True) | Q(max_amount__gte=total_amount)
