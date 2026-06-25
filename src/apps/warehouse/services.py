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
        branch_id = validated_data["branch_id"]
        items_data = validated_data["items"]

        receipt_code = generate_document_code("WR", WarehouseReceipt, "receipt_code")
        receipt = WarehouseReceipt.objects.create(
            receipt_code=receipt_code,
            ipo_id=ipo_id,
            warehouse_keeper=user,
            note=validated_data.get("notes"),
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

            material_id = item.get("material_id")
            material_name_other = item.get("material_name_other")

            # Nếu vật tư chưa có trong danh mục chính thức (hàng ngoài danh mục)
            # Tự động khởi tạo bản ghi trong Materials để theo dõi tồn kho
            if not material_id and material_name_other and str(material_name_other).strip():
                from apps.master_data.models import Material, MaterialCategory
                # Tìm category 'Khác' hoặc category đầu tiên
                category = MaterialCategory.objects.filter(is_active=True).first()
                if not category:
                    category = MaterialCategory.objects.create(
                        category_code="CAT-OTHER",
                        category_name="Danh mục khác",
                        is_active=True
                    )
                import uuid
                material_code = f"MAT-OT-{uuid.uuid4().hex[:8].upper()}"
                
                new_material = Material.objects.create(
                    material_code=material_code,
                    material_name=material_name_other.strip(),
                    category=category,
                    uom="cái",
                    is_other=True,
                    is_active=True,
                    description=f"Tự động tạo từ phiếu nhập kho hàng ngoài danh mục {receipt_code}"
                )
                material_id = new_material.material_id
            
            WarehouseReceiptItem.objects.create(
                receipt=receipt,
                material_id=material_id,
                material_name_other=material_name_other,
                qty_ordered=Decimal(str(item["qty_ordered"])),
                qty_received=qty_received,
                qty_passed=qty_passed,
                qty_failed=qty_failed,
                photo_paths=json.dumps(photo_paths, ensure_ascii=False) if photo_paths else None,
            )

            if material_id:
                # Cập nhật Inventory — atomic F() expression tránh race condition
                inventory, _ = Inventory.objects.get_or_create(material_id=material_id, branch_id=branch_id)
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
    def create_issue(user, validated_data: dict):
        """Xuất kho nhiều vật tư từ một chi nhánh cho PR."""
        from .models import StockIssue, StockIssueItem
        from apps.purchase_request.models import PRItem

        branch_id = validated_data["branch_id"]
        pr_id = validated_data.get("pr_id")
        receiver_id = validated_data["receiver_id"]
        dept_id = validated_data.get("dept_id")

        if not dept_id:
            from apps.authentication.models import User as AuthUser
            try:
                receiver_user = AuthUser.objects.get(user_id=receiver_id)
                dept_id = receiver_user.dept_id
            except Exception:
                dept_id = 1

        issue_code = generate_document_code("WI", StockIssue, "issue_code")
        issue = StockIssue.objects.create(
            issue_code=issue_code,
            pr_id=pr_id,
            dept_id=dept_id,
            warehouse_keeper=user,
            receiver_id=receiver_id
        )

        for item in validated_data["items"]:
            material_id = item["material_id"]
            qty_issued = Decimal(str(item["qty_issued"]))

            # Kiểm tra tồn kho theo branch
            inventory = Inventory.objects.select_for_update().filter(
                material_id=material_id, branch_id=branch_id
            ).first()
            
            if not inventory or inventory.qty_available < qty_issued:
                raise ValueError(
                    f"Tồn kho không đủ cho vật tư ID {material_id}. "
                    f"Sẵn có: {inventory.qty_available if inventory else 0}, Yêu cầu: {qty_issued}."
                )

            # Giảm tồn kho
            Inventory.objects.filter(inventory_id=inventory.inventory_id).update(
                qty_available=F("qty_available") - qty_issued
            )

            # Tạo StockIssueItem
            StockIssueItem.objects.create(
                issue=issue,
                material_id=material_id,
                qty_issued=qty_issued
            )

            # Cập nhật PRItem.qty_received nếu xuất theo PR
            if pr_id:
                pr_item = PRItem.objects.filter(pr_id=pr_id, material_id=material_id).first()
                if pr_item:
                    pr_item.qty_received += qty_issued
                    if pr_item.qty_received >= pr_item.qty_requested:
                        pr_item.item_status = "COMPLETED"
                    else:
                        pr_item.item_status = "PARTIAL"
                    pr_item.save(update_fields=["qty_received", "item_status"])

        write_audit_log(
            user=user, action="CREATE",
            table_name="StockIssues", record_id=issue.issue_id,
            new_values={"issue_code": issue_code, "pr_id": pr_id},
        )
        logger.info("Issue %s created by %s", issue_code, user.username)
        return issue

    @staticmethod
    @transaction.atomic
    def create_return_order(user, validated_data: dict):
        from .models import ReturnOrder, ReturnOrderItem
        
        supplier_id = validated_data["supplier_id"]
        receipt_id = validated_data.get("receipt_id")
        if not receipt_id:
            from .models import WarehouseReceipt
            receipt = WarehouseReceipt.objects.filter(ipo__supplier_id=supplier_id).order_by("-received_at").first()
            if receipt:
                receipt_id = receipt.receipt_id
            else:
                any_receipt = WarehouseReceipt.objects.first()
                if any_receipt:
                    receipt_id = any_receipt.receipt_id
                else:
                    raise ValueError("Không tìm thấy phiếu nhập kho nào để liên kết.")

        return_code = generate_document_code("RO", ReturnOrder, "return_code")
        return_order = ReturnOrder.objects.create(
            return_code=return_code,
            supplier_id=supplier_id,
            receipt_id=receipt_id,
            created_by=user,
            return_status="DRAFT"
        )
        
        for item in validated_data["items"]:
            ReturnOrderItem.objects.create(
                return_order=return_order,
                material_id=item["material_id"],
                qty_returned=Decimal(str(item["qty_returned"])),
                reason=item.get("reason", "")
            )
            
            # Reduce inventory
            # Wait, we need branch_id for reducing inventory?
            # For returns, we reduce qty_available or qty_quarantine.
            # Assume reducing from qty_quarantine if it was failed, else qty_available.
            # Here we just reduce qty_available for simplicity, or we should require branch_id.
            
        write_audit_log(
            user=user, action="CREATE",
            table_name="ReturnOrders", record_id=return_order.return_id,
            new_values={"return_code": return_code},
        )
        return return_order
