"""
IPOService: tạo version mới, flip is_latest, kiểm tra qty constraint.
"""
import logging
from decimal import Decimal

from django.db import transaction

from core.utils.audit import write_audit_log
from core.utils.code_generator import generate_document_code

from .models import IPO, IPOItem

logger = logging.getLogger("apps")


class IPOService:

    @staticmethod
    @transaction.atomic
    def create_version(user, validated_data: dict) -> IPO:
        """
        Tạo phiên bản IPO mới.
        Nếu đã có phiên bản trước (cùng ipo_code): flip is_latest cũ → False, tạo version mới.
        Nếu lần đầu: tạo mới với version=1.

        Rule: sum(qty_final) <= qty_requested trên PR gốc — kiểm tra trước khi lưu.
        """
        order_id = validated_data["order_id"]
        supplier_id = validated_data["supplier_id"]
        items_data = validated_data["items"]

        # Kiểm tra qty constraint
        IPOService._validate_qty_constraints(order_id, items_data)

        # Xác định ipo_code và version
        existing_latest = IPO.objects.filter(
            order_id=order_id, supplier_id=supplier_id, is_latest=True
        ).first()

        if existing_latest:
            ipo_code = existing_latest.ipo_code
            new_version = existing_latest.version + 1
            # Hạ cờ phiên bản cũ
            IPO.objects.filter(
                order_id=order_id, supplier_id=supplier_id
            ).update(is_latest=False)
        else:
            ipo_code = generate_document_code("IPO", IPO, "ipo_code")
            new_version = 1

        # Tính tổng tiền
        total = sum(
            Decimal(str(item["qty_final"])) * Decimal(str(item["unit_price"]))
            for item in items_data
        )

        ipo = IPO.objects.create(
            ipo_code=ipo_code,
            version=new_version,
            is_latest=True,
            order_id=order_id,
            supplier_id=supplier_id,
            buyer=user,
            total_amount=total,
            ipo_status="DRAFT",
        )

        ipo_items = [
            IPOItem(
                ipo=ipo,
                order_item_id=item["order_item_id"],
                qty_final=item["qty_final"],
                unit_price=item["unit_price"],
                total_price=Decimal(str(item["qty_final"])) * Decimal(str(item["unit_price"])),
            )
            for item in items_data
        ]
        IPOItem.objects.bulk_create(ipo_items)

        write_audit_log(
            user=user, action="CREATE",
            table_name="IPOs", record_id=ipo.ipo_id,
            new_values={"ipo_code": ipo_code, "version": new_version, "total": str(total)},
        )
        logger.info("IPO %s v%d created by %s", ipo_code, new_version, user.username)
        return ipo

    @staticmethod
    @transaction.atomic
    def submit_for_approval(ipo: IPO, user) -> IPO:
        if ipo.ipo_status != "DRAFT":
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Chỉ nộp phê duyệt IPO ở trạng thái DRAFT.")

        from apps.master_data.services import ApprovalMatrixService
        from apps.purchase_request.models import DocumentApprovalProgress, PRStatusHistory

        workflow = ApprovalMatrixService.resolve_workflow(
            object_type="IPO",
            total_amount=ipo.total_amount,
        )
        if not workflow:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Không tìm thấy luồng phê duyệt cho IPO.")

        ipo.ipo_status = "PENDING"
        ipo.save(update_fields=["ipo_status", "updated_at"])

        steps = list(workflow.steps.order_by("step_sequence"))
        DocumentApprovalProgress.objects.bulk_create([
            DocumentApprovalProgress(
                document_type="IPO",
                document_id=ipo.ipo_id,
                step_sequence=step.step_sequence,
                approval_status="PENDING",
            )
            for step in steps
        ])

        write_audit_log(
            user=user, action="SUBMIT",
            table_name="IPOs", record_id=ipo.ipo_id,
            new_values={"status": "PENDING"},
        )
        return ipo

    @staticmethod
    @transaction.atomic
    def process_approval(ipo: IPO, approver, action: str, comment: str = "") -> IPO:
        from apps.purchase_request.models import DocumentApprovalProgress
        from django.utils import timezone

        current_step = (
            DocumentApprovalProgress.objects.filter(
                document_type="IPO",
                document_id=ipo.ipo_id,
                approval_status="PENDING",
            ).order_by("step_sequence").first()
        )
        if not current_step:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Không tìm thấy bước phê duyệt đang chờ.")

        current_step.approver = approver
        current_step.approval_status = "APPROVED" if action == "APPROVE" else "REJECTED"
        current_step.comment = comment
        current_step.action_date = timezone.now()
        current_step.save()

        if action == "REJECT":
            ipo.ipo_status = "REJECTED"
        else:
            has_next = DocumentApprovalProgress.objects.filter(
                document_type="IPO",
                document_id=ipo.ipo_id,
                approval_status="PENDING",
            ).exists()
            if not has_next:
                ipo.ipo_status = "APPROVED"

        ipo.save(update_fields=["ipo_status", "updated_at"])
        write_audit_log(
            user=approver, action=action,
            table_name="IPOs", record_id=ipo.ipo_id,
            new_values={"action": action, "step": current_step.step_sequence},
        )
        return ipo

    @staticmethod
    def _validate_qty_constraints(order_id: int, items_data: list) -> None:
        """
        Kiểm tra: sum(qty_final mới) + sum(qty_final đã duyệt trước)
                  <= qty_requested trên PR gốc.
        """
        from apps.cart_order.models import OrderItem, OrderItemPRLink
        from rest_framework.exceptions import ValidationError

        for item in items_data:
            order_item_id = item["order_item_id"]
            qty_new = Decimal(str(item["qty_final"]))

            # Tổng qty đã gom lên IPO được duyệt từ trước
            existing_qty = (
                IPOItem.objects.filter(
                    order_item_id=order_item_id,
                    ipo__is_latest=True,
                    ipo__ipo_status="APPROVED",
                )
                .aggregate(total=models_sum("qty_final"))["total"]
                or Decimal("0")
            )

            # qty_requested gốc từ PRItem
            pr_qty = (
                OrderItemPRLink.objects.filter(order_item_id=order_item_id)
                .aggregate(total=models_sum("qty_linked"))["total"]
                or Decimal("0")
            )

            if (existing_qty + qty_new) > pr_qty:
                raise ValidationError(
                    f"OrderItem #{order_item_id}: tổng qty_final "
                    f"({existing_qty + qty_new}) vượt quá qty_requested ({pr_qty})."
                )


def models_sum(field: str):
    from django.db.models import Sum
    return Sum(field)
