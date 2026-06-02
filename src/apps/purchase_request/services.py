"""
PRService: toàn bộ business logic cho Purchase Request.
Views chỉ gọi vào đây — không chứa logic trong views.py.
"""
import logging
from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from apps.master_data.services import ApprovalMatrixService
from core.utils.audit import write_audit_log
from core.utils.code_generator import generate_document_code

from .models import DocumentApprovalProgress, PRItem, PRStatusHistory, PurchaseRequisition

logger = logging.getLogger("apps")


class PRService:

    @staticmethod
    @transaction.atomic
    def create_pr(user, validated_data: dict) -> PurchaseRequisition:
        """
        Tạo đơn PR mới kèm các dòng hàng.
        Tự sinh pr_code, tính total_estimated_amount.
        """
        priority = validated_data["priority_level"]
        items_data = validated_data["items"]

        # Tính tổng tiền ước tính
        total = sum(
            Decimal(str(item["qty_requested"])) * Decimal(str(item.get("estimated_unit_price", 0)))
            for item in items_data
        )

        # Sinh mã PR
        pr_code = generate_document_code("PR", PurchaseRequisition, "pr_code")

        pr = PurchaseRequisition.objects.create(
            pr_code=pr_code,
            requester=user,
            branch=user.branch,
            dept=user.dept,
            priority_level=priority,
            urgent_reason=validated_data.get("urgent_reason"),
            urgency_impact=validated_data.get("urgency_impact"),
            pr_status="DRAFT",
            total_estimated_amount=total,
        )

        # Tạo các dòng hàng
        pr_items = []
        for item in items_data:
            pr_items.append(PRItem(
                pr=pr,
                material_id=item.get("material_id"),
                material_name_other=item.get("material_name_other"),
                qty_requested=item["qty_requested"],
                estimated_unit_price=item.get("estimated_unit_price", 0),
                required_deadline=item["required_deadline"],
            ))
        PRItem.objects.bulk_create(pr_items)

        write_audit_log(
            user=user,
            action="CREATE",
            table_name="PurchaseRequisitions",
            record_id=pr.pr_id,
            new_values={"pr_code": pr_code, "priority": priority, "total": str(total)},
        )
        logger.info("PR created: %s by user %s", pr_code, user.username)
        return pr

    @staticmethod
    @transaction.atomic
    def submit_for_approval(pr: PurchaseRequisition, user) -> PurchaseRequisition:
        """
        Chuyển PR từ DRAFT → PENDING và khởi tạo các bước phê duyệt.
        """
        if pr.pr_status != "DRAFT":
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Chỉ có thể nộp phê duyệt đơn ở trạng thái DRAFT.")

        object_type = (
            "PR_URGENT" if pr.priority_level == "URGENT" else "PR_NORMAL"
        )
        workflow = ApprovalMatrixService.resolve_workflow(
            object_type=object_type,
            total_amount=pr.total_estimated_amount,
            dept_id=pr.dept_id,
        )

        if not workflow:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Không tìm thấy luồng phê duyệt phù hợp. Liên hệ quản trị viên.")

        old_status = pr.pr_status
        pr.pr_status = "PENDING"
        pr.save(update_fields=["pr_status", "updated_at"])

        # Tạo các bước phê duyệt từ workflow
        steps = list(workflow.steps.order_by("step_sequence"))
        progress_records = [
            DocumentApprovalProgress(
                document_type="PR",
                document_id=pr.pr_id,
                step_sequence=step.step_sequence,
                approval_status="PENDING",
            )
            for step in steps
        ]
        DocumentApprovalProgress.objects.bulk_create(progress_records)

        PRStatusHistory.objects.create(
            pr=pr,
            from_status=old_status,
            to_status="PENDING",
            changed_by=user,
            note=f"Nộp phê duyệt. Luồng: {workflow.workflow_name}",
        )

        # Gửi thông báo nếu là đơn khẩn
        if pr.priority_level == "URGENT":
            PRService._notify_urgent(pr, workflow, steps)

        write_audit_log(
            user=user, action="SUBMIT",
            table_name="PurchaseRequisitions",
            record_id=pr.pr_id,
            old_values={"status": old_status},
            new_values={"status": "PENDING", "workflow": workflow.workflow_name},
        )
        return pr

    @staticmethod
    @transaction.atomic
    def process_approval(pr: PurchaseRequisition, approver, action: str, comment: str = "") -> PurchaseRequisition:
        """
        Xử lý phê duyệt / từ chối tại bước hiện tại.
        action: "APPROVE" | "REJECT"
        """
        if pr.pr_status != "PENDING":
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Chứng từ không ở trạng thái chờ duyệt.")

        # Tìm bước đang chờ (nhỏ nhất)
        current_step = (
            DocumentApprovalProgress.objects.filter(
                document_type="PR",
                document_id=pr.pr_id,
                approval_status="PENDING",
            )
            .order_by("step_sequence")
            .first()
        )

        if not current_step:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Không tìm thấy bước phê duyệt đang chờ.")

        # Kiểm tra approver có role đúng không
        if not PRService._approver_has_permission(approver, pr, current_step.step_sequence):
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Bạn không có quyền phê duyệt bước này.")

        # Cập nhật bước hiện tại
        current_step.approver = approver
        current_step.approval_status = "APPROVED" if action == "APPROVE" else "REJECTED"
        current_step.comment = comment
        current_step.action_date = timezone.now()
        current_step.save()

        if action == "REJECT":
            # Từ chối → toàn bộ chứng từ REJECTED
            pr.pr_status = "REJECTED"
            pr.save(update_fields=["pr_status", "updated_at"])
            PRStatusHistory.objects.create(
                pr=pr, from_status="PENDING", to_status="REJECTED",
                changed_by=approver, note=comment,
            )
        else:
            # Kiểm tra còn bước tiếp theo không
            next_step = DocumentApprovalProgress.objects.filter(
                document_type="PR",
                document_id=pr.pr_id,
                approval_status="PENDING",
            ).order_by("step_sequence").first()

            if not next_step:
                # Duyệt hết → APPROVED
                pr.pr_status = "APPROVED"
                pr.save(update_fields=["pr_status", "updated_at"])
                PRStatusHistory.objects.create(
                    pr=pr, from_status="PENDING", to_status="APPROVED",
                    changed_by=approver, note="Hoàn tất phê duyệt tất cả các cấp.",
                )

        write_audit_log(
            user=approver, action=action,
            table_name="PurchaseRequisitions",
            record_id=pr.pr_id,
            new_values={"action": action, "step": current_step.step_sequence, "comment": comment},
        )
        return pr

    @staticmethod
    def _approver_has_permission(approver, pr, step_sequence: int) -> bool:
        """Kiểm tra approver có role phù hợp với bước phê duyệt."""
        from apps.master_data.models import ApprovalWorkflowStep
        return ApprovalWorkflowStep.objects.filter(
            workflow__object_type__in=["PR_NORMAL", "PR_URGENT"],
            step_sequence=step_sequence,
            role=approver.role,
        ).exists()

    @staticmethod
    def _notify_urgent(pr, workflow, steps):
        """Gửi email thông báo async cho approver của bước 1 khi có PR khẩn."""
        from infrastructure.tasks.email_tasks import send_urgent_pr_notification_email
        from apps.authentication.models import User

        if not steps:
            return
        first_step = steps[0]
        approvers = User.objects.filter(role=first_step.role, is_active=True)
        for approver in approvers:
            send_urgent_pr_notification_email.delay(
                approver_email=approver.email,
                approver_name=approver.full_name,
                pr_code=pr.pr_code,
                requester_name=pr.requester.full_name,
                urgent_reason=pr.urgent_reason or "",
            )
