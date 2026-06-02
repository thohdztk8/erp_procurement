"""
MatchingService: đối soát 3 chiều (Invoice × IPO × WarehouseReceipt).
PaymentService: tạo và duyệt yêu cầu thanh toán.
"""
import logging
from decimal import Decimal

from django.db import transaction

from core.utils.audit import write_audit_log
from core.utils.code_generator import generate_document_code

from .models import (
    CreditNote, DebitNote, Invoice, InvoiceItem,
    PaymentRequest, ThreeWayMatchingResult,
)

logger = logging.getLogger("apps")


class MatchingService:

    @staticmethod
    @transaction.atomic
    def create_invoice(user, validated_data: dict) -> Invoice:
        """Tạo hóa đơn đỏ từ NCC."""
        items_data = validated_data.pop("items")
        invoice = Invoice.objects.create(created_by=user, **validated_data)

        InvoiceItem.objects.bulk_create([
            InvoiceItem(
                invoice=invoice,
                ipo_item_id=item["ipo_item_id"],
                qty_invoice=item["qty_invoice"],
                price_invoice=item["price_invoice"],
            )
            for item in items_data
        ])

        write_audit_log(
            user=user, action="CREATE",
            table_name="Invoices", record_id=invoice.invoice_id,
            new_values={"invoice_code": invoice.invoice_code, "total": str(invoice.total_invoice_amount)},
        )
        return invoice

    @staticmethod
    @transaction.atomic
    def run_three_way_matching(invoice: Invoice, user) -> ThreeWayMatchingResult:
        """
        Thuật toán đối soát 3 chiều:
        1. Hóa đơn tài chính: qty_invoice, price_invoice
        2. Đơn đặt hàng IPO: price_ipo (đơn giá cam kết)
        3. Phiếu nhập kho: qty_received_passed (số lượng thực nhập đạt IQC)

        qty_diff  = qty_invoice - qty_received_passed
        price_diff = price_invoice - price_ipo
        is_error  = (qty_diff != 0) OR (price_diff != 0)
        """
        from apps.warehouse.models import WarehouseReceiptItem

        has_error = False
        results = []

        for inv_item in invoice.items.select_related("ipo_item"):
            ipo_item = inv_item.ipo_item

            # Lấy đơn giá từ IPO
            price_ipo = ipo_item.unit_price

            # Lấy qty đã nhập kho và đạt IQC (tổng tất cả receipts của IPO item này)
            from django.db.models import Sum
            qty_passed_agg = (
                WarehouseReceiptItem.objects.filter(ipo_item=ipo_item)
                .aggregate(total=Sum("qty_passed"))["total"]
            ) or Decimal("0")

            qty_diff = inv_item.qty_invoice - qty_passed_agg
            price_diff = inv_item.price_invoice - price_ipo
            item_error = (qty_diff != 0) or (price_diff != 0)

            if item_error:
                has_error = True

            results.append({
                "invoice_item": inv_item,
                "receipt_qty_passed": qty_passed_agg,
                "qty_diff": qty_diff,
                "price_ipo": price_ipo,
                "price_diff": price_diff,
                "is_error": item_error,
            })

        # Lưu kết quả đối soát (lấy item đầu tiên làm đại diện nếu nhiều dòng)
        first = results[0]
        receipt_item = (
            WarehouseReceiptItem.objects.filter(ipo_item=first["invoice_item"].ipo_item).first()
        )

        matching = ThreeWayMatchingResult.objects.update_or_create(
            invoice=invoice,
            defaults={
                "invoice_item": first["invoice_item"],
                "receipt_item": receipt_item,
                "qty_invoice": first["invoice_item"].qty_invoice,
                "qty_received_passed": first["receipt_qty_passed"],
                "qty_diff": first["qty_diff"],
                "price_invoice": first["invoice_item"].price_invoice,
                "price_ipo": first["price_ipo"],
                "price_diff": first["price_diff"],
                "is_error": has_error,
                "is_overridden": False,
            },
        )[0]

        # Cập nhật trạng thái Invoice
        invoice.invoice_status = "MISMATCHED" if has_error else "MATCHED"
        invoice.save(update_fields=["invoice_status"])

        write_audit_log(
            user=user, action="MATCHING",
            table_name="Invoices", record_id=invoice.invoice_id,
            new_values={"is_error": has_error, "invoice_status": invoice.invoice_status},
        )
        logger.info("3-way matching done: invoice=%s error=%s", invoice.invoice_code, has_error)
        return matching

    @staticmethod
    @transaction.atomic
    def override_matching(invoice: Invoice, user, override_note: str) -> ThreeWayMatchingResult:
        """
        Ban Giám đốc override sai lệch — bắt buộc ghi lý do.
        Chỉ role có permission OVERRIDE_MATCHING mới được gọi.
        """
        matching = invoice.matching_result
        if not matching.is_error:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Hóa đơn không có sai lệch để override.")

        matching.is_overridden = True
        matching.override_note = override_note
        matching.overridden_by = user
        matching.save(update_fields=["is_overridden", "override_note", "overridden_by"])

        invoice.invoice_status = "MATCHED"
        invoice.save(update_fields=["invoice_status"])

        write_audit_log(
            user=user, action="OVERRIDE_MATCHING",
            table_name="Invoices", record_id=invoice.invoice_id,
            new_values={"override_note": override_note, "overridden_by": user.username},
        )
        return matching


class PaymentService:

    @staticmethod
    @transaction.atomic
    def create_payment_request(user, invoice: Invoice) -> PaymentRequest:
        if invoice.invoice_status not in ("MATCHED",):
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Chỉ tạo yêu cầu thanh toán cho hóa đơn đã đối soát khớp.")

        payment, created = PaymentRequest.objects.get_or_create(
            invoice=invoice,
            defaults={
                "amount": invoice.total_invoice_amount,
                "payment_status": "PENDING",
                "requested_by": user,
            },
        )
        if not created:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Yêu cầu thanh toán đã tồn tại cho hóa đơn này.")

        write_audit_log(
            user=user, action="CREATE",
            table_name="PaymentRequests", record_id=payment.payment_id,
            new_values={"invoice_id": invoice.invoice_id, "amount": str(payment.amount)},
        )
        return payment

    @staticmethod
    @transaction.atomic
    def approve_payment(user, payment: PaymentRequest, action: str, note: str = "") -> PaymentRequest:
        from django.utils import timezone
        payment.payment_status = "APPROVED" if action == "APPROVE" else "REJECTED"
        payment.approved_by = user
        payment.note = note
        if action == "APPROVE":
            payment.payment_date = timezone.now().date()
        payment.save()

        if action == "APPROVE":
            payment.invoice.invoice_status = "PAID"
            payment.invoice.save(update_fields=["invoice_status"])

        write_audit_log(
            user=user, action=action,
            table_name="PaymentRequests", record_id=payment.payment_id,
            new_values={"action": action, "note": note},
        )
        return payment
