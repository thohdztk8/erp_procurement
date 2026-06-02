"""
WarehouseService: nhập kho IQC, cập nhật Inventory trong atomic transaction.
Rule: qty_received = qty_passed + qty_failed
      qty_passed → qty_available
      qty_failed → qty_quarantine
"""
import json
import logging
from decimal import Decimal

from django.db import transaction
from django.db.models import F

from core.utils.audit import write_audit_log
from core.utils.code_generator import generate_document_code

from .models import Inventory, WarehouseReceipt, WarehouseReceiptItem

logger = logging.getLogger("apps")


class WarehouseService:

    @staticmethod
    @transaction.atomic
    def create_receipt(user, validated_data: dict) -> WarehouseReceipt:
        """
        Lập phiếu nhập kho + IQC.
        Cập nhật Inventory trong cùng transaction — rollback toàn bộ nếu lỗi.
        """
        ipo_id = validated_data["ipo_id"]
        items_data = validated_data["items"]

        receipt_code = generate_document_code("WR", WarehouseReceipt, "receipt_code")
        receipt = WarehouseReceipt.objects.create(
            receipt_code=receipt_code,
            ipo_id=ipo_id,
            receiver=user,
            notes=validated_data.get("notes"),
        )

        for item in items_data:
            qty_received = Decimal(str(item["qty_received"]))
            qty_passed = Decimal(str(item["qty_passed"]))
            qty_failed = Decimal(str(item["qty_failed"]))

            # Validate phương trình cân bằng
            if qty_passed + qty_failed != qty_received:
                raise ValueError(
                    f"IQC error: qty_received ({qty_received}) ≠ "
                    f"qty_passed ({qty_passed}) + qty_failed ({qty_failed})"
                )

            photo_paths = item.get("photo_paths", [])
            if qty_failed > 0 and not photo_paths:
                raise ValueError("Bắt buộc có ảnh minh chứng khi qty_failed > 0.")

            WarehouseReceiptItem.objects.create(
                receipt=receipt,
                ipo_item_id=item["ipo_item_id"],
                qty_received=qty_received,
                qty_passed=qty_passed,
                qty_failed=qty_failed,
                photo_paths=json.dumps(photo_paths, ensure_ascii=False) if photo_paths else None,
                failure_reason=item.get("failure_reason"),
            )

            # Lấy material_id từ IPOItem
            from apps.ipo.models import IPOItem
            ipo_item = IPOItem.objects.select_related("order_item__material").get(
                ipo_item_id=item["ipo_item_id"]
            )
            material_id = ipo_item.order_item.material_id

            if material_id:
                # Cập nhật Inventory — atomic F() expression tránh race condition
                inventory, _ = Inventory.objects.get_or_create(material_id=material_id)
                Inventory.objects.filter(inventory_id=inventory.inventory_id).update(
                    qty_available=F("qty_available") + qty_passed,
                    qty_quarantine=F("qty_quarantine") + qty_failed,
                )

        write_audit_log(
            user=user, action="CREATE",
            table_name="WarehouseReceipts", record_id=receipt.receipt_id,
            new_values={"receipt_code": receipt_code, "ipo_id": ipo_id},
        )
        logger.info("Receipt %s created for IPO %d by %s", receipt_code, ipo_id, user.username)
        return receipt

    @staticmethod
    @transaction.atomic
    def issue_material(user, material_id: int, qty: Decimal, issued_to_user_id: int, purpose: str = "") -> None:
        """Xuất vật tư khỏi kho — trừ qty_available."""
        from .models import WarehouseIssue

        inventory = Inventory.objects.select_for_update().get(material_id=material_id)
        if inventory.qty_available < qty:
            from rest_framework.exceptions import ValidationError
            raise ValidationError(
                f"Tồn kho không đủ. Sẵn có: {inventory.qty_available}, yêu cầu: {qty}."
            )

        issue_code = generate_document_code("WI", WarehouseIssue, "issue_code")
        WarehouseIssue.objects.create(
            issue_code=issue_code,
            material_id=material_id,
            qty_issued=qty,
            issued_to_id=issued_to_user_id,
            issued_by=user,
            purpose=purpose,
        )

        Inventory.objects.filter(inventory_id=inventory.inventory_id).update(
            qty_available=F("qty_available") - qty
        )

        write_audit_log(
            user=user, action="ISSUE",
            table_name="Inventory", record_id=inventory.inventory_id,
            new_values={"qty_issued": str(qty), "material_id": material_id},
        )
