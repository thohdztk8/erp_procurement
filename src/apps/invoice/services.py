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
    PaymentRequest, InvoiceMatchingResult,
    SupplierEvaluation, SupplierEvaluationCriteria
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
            new_values={"invoice_number": invoice.invoice_number, "total": str(invoice.total_amount)},
        )
        return invoice

    @staticmethod
    @transaction.atomic
    def run_three_way_matching(invoice: Invoice, user) -> InvoiceMatchingResult:
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

            # Lấy qty đã nhập kho và đạt IQC (tổng tất cả receipts của IPO này cho material tương ứng)
            from django.db.models import Sum
            qty_passed_agg = (
                WarehouseReceiptItem.objects.filter(
                    receipt__ipo_id=ipo_item.ipo_id,
                    material_id=ipo_item.material_id
                ).aggregate(total=Sum("qty_passed"))["total"]
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
            WarehouseReceiptItem.objects.filter(
                receipt__ipo_id=first["invoice_item"].ipo_item.ipo_id,
                material_id=first["invoice_item"].ipo_item.material_id
            ).first()
        )

        matching = InvoiceMatchingResult.objects.update_or_create(
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
                "log_details_json": "{}",
            },
        )[0]

        # Cập nhật trạng thái Invoice
        invoice.matching_status = "MISMATCHED" if has_error else "MATCHED"
        invoice.save(update_fields=["matching_status"])

        write_audit_log(
            user=user, action="MATCHING",
            table_name="Invoices", record_id=invoice.invoice_id,
            new_values={"is_error": has_error, "invoice_status": invoice.invoice_status},
        )
        logger.info("3-way matching done: invoice=%s error=%s", invoice.invoice_code, has_error)
        return matching

    @staticmethod
    @transaction.atomic
    def override_matching(invoice: Invoice, user, override_note: str) -> InvoiceMatchingResult:
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
        # log_details_json instead? The original model had is_overridden, but we changed to log_details_json?
        # Actually I need to check InvoiceMatchingResult model.
        # It has log_details_json, no is_overridden.
        import json
        try:
            logs = json.loads(matching.log_details_json) if matching.log_details_json else {}
        except:
            logs = {}
        logs["overridden"] = True
        logs["override_note"] = override_note
        logs["overridden_by"] = user.username
        matching.log_details_json = json.dumps(logs)
        matching.save(update_fields=["log_details_json"])

        invoice.matching_status = "MATCHED"
        invoice.save(update_fields=["matching_status"])

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
        if invoice.matching_status not in ("MATCHED",):
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Chỉ tạo yêu cầu thanh toán cho hóa đơn đã đối soát khớp.")
            
        payment_code = generate_document_code("PAY", PaymentRequest, "payment_req_code")

        payment, created = PaymentRequest.objects.get_or_create(
            invoice=invoice,
            defaults={
                "payment_req_code": payment_code,
                "requested_amount": invoice.total_amount,
                "req_status": "PENDING",
                "applicant": user,
            },
        )
        if not created:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Yêu cầu thanh toán đã tồn tại cho hóa đơn này.")

        write_audit_log(
            user=user, action="CREATE",
            table_name="PaymentRequests", record_id=payment.payment_req_id,
            new_values={"invoice_id": invoice.invoice_id, "amount": str(payment.requested_amount)},
        )
        return payment

    @staticmethod
    @transaction.atomic
    def approve_payment(user, payment: PaymentRequest, action: str, note: str = "") -> PaymentRequest:
        from django.utils import timezone
        payment.req_status = "APPROVED" if action == "APPROVE" else "REJECTED"
        payment.approver = user
        payment.note = note
        if action == "APPROVE":
            payment.payment_deadline = timezone.now().date()
        payment.save()

        # Giả định hóa đơn có trạng thái thanh toán riêng hoặc dùng matching_status
        # Invoice ko có status payment theo model mới. Chúng ta không update status invoice nữa

        write_audit_log(
            user=user, action=action,
            table_name="PaymentRequests", record_id=payment.payment_req_id,
            new_values={"action": action, "note": note},
        )
        return payment

class EvaluationService:

    @staticmethod
    @transaction.atomic
    def evaluate_supplier(user, supplier_id: int, period_type: str, period_value: str, start_date, end_date):
        from apps.warehouse.models import StockReceiptItem
        from django.db.models import Sum

        # Lấy dữ liệu receipt
        receipts = StockReceiptItem.objects.filter(
            receipt__ipo__supplier_id=supplier_id,
            receipt__received_at__gte=start_date,
            receipt__received_at__lte=end_date
        )

        agg = receipts.aggregate(
            total_passed=Sum('qty_passed'),
            total_failed=Sum('qty_failed')
        )
        total_passed = agg['total_passed'] or Decimal('0')
        total_failed = agg['total_failed'] or Decimal('0')
        total_received = total_passed + total_failed

        # Giả lập tính điểm chất lượng (50đ max)
        quality_score = Decimal('50.00')
        if total_received > 0:
            quality_score = (total_passed / total_received) * Decimal('50.00')

        # Giả lập điểm thời gian (50đ max) - Tạm cho 50
        time_score = Decimal('50.00')

        total_score = quality_score + time_score

        # Xếp hạng
        if total_score >= 90:
            rank = "GOLD"
        elif total_score >= 70:
            rank = "SILVER"
        elif total_score >= 50:
            rank = "BRONZE"
        else:
            rank = "WARNING"

        eval_obj, created = SupplierEvaluation.objects.update_or_create(
            supplier_id=supplier_id,
            period_type=period_type,
            period_value=period_value,
            defaults={
                "period_start_date": start_date,
                "period_end_date": end_date,
                "total_score": total_score,
                "rank": rank,
                "evaluator": user
            }
        )

        # Lưu tiêu chí
        SupplierEvaluationCriteria.objects.update_or_create(
            evaluation=eval_obj,
            criteria_code="QUALITY",
            defaults={
                "criteria_name": "Chất lượng hàng hóa",
                "raw_score": quality_score,
                "weight": Decimal('0.5'),
                "weighted_score": quality_score
            }
        )
        SupplierEvaluationCriteria.objects.update_or_create(
            evaluation=eval_obj,
            criteria_code="TIME",
            defaults={
                "criteria_name": "Thời gian giao hàng",
                "raw_score": time_score,
                "weight": Decimal('0.5'),
                "weighted_score": time_score
            }
        )

        return eval_obj
