"""
QuotationService: sinh token SHA-256, gửi mail async,
quản lý version báo giá, chốt phương án NCC.
"""
import json
import logging
from datetime import timedelta
from decimal import Decimal

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from core.utils.audit import write_audit_log
from core.utils.token_generator import generate_vendor_token

from .models import (
    Quotation, QuotationItem, QuotationRequest,
    QuotationToken, QuotationVersion,
)

logger = logging.getLogger("apps")


class QuotationService:

    @staticmethod
    @transaction.atomic
    def invite_suppliers(user, order_id: int, supplier_ids: list[int], deadline) -> list[QuotationRequest]:
        """
        Tạo QuotationRequest + QuotationToken cho mỗi NCC.
        Gửi email mời báo giá async qua Celery.
        """
        from apps.cart_order.models import Order
        from infrastructure.tasks.email_tasks import send_quotation_invite_email

        order = Order.objects.prefetch_related("order_suppliers").get(order_id=order_id)
        requests_created = []

        for supplier_id in supplier_ids:
            from apps.master_data.models import Supplier
            supplier = Supplier.objects.get(supplier_id=supplier_id)

            # Tạo QuotationRequest
            q_request, created = QuotationRequest.objects.get_or_create(
                order=order,
                supplier=supplier,
                defaults={"deadline_submission": deadline},
            )

            # Sinh token mới (raw gửi mail, hashed lưu DB)
            raw_token, hashed_token = generate_vendor_token()

            expire_hours = settings.QUOTATION_TOKEN_EXPIRE_HOURS
            QuotationToken.objects.update_or_create(
                q_request=q_request,
                defaults={
                    "token": hashed_token,
                    "expires_at": timezone.now() + timedelta(hours=expire_hours),
                    "is_used": False,
                    "used_at": None,
                },
            )

            portal_url = (
                f"{settings.VENDOR_PORTAL_BASE_URL}?token={raw_token}"
                f"&request={q_request.q_request_id}"
            )

            # Gửi email async
            send_quotation_invite_email.delay(
                supplier_email=supplier.contact_email,
                supplier_name=supplier.supplier_name,
                order_code=order.order_code,
                portal_url=portal_url,
                deadline=deadline.strftime("%d/%m/%Y %H:%M"),
            )

            requests_created.append(q_request)
            logger.info("Quotation invite sent: order=%s supplier=%s", order.order_code, supplier.supplier_code)

        # Cập nhật trạng thái Order → QUOTING
        order.order_status = "QUOTING"
        order.save(update_fields=["order_status"])

        write_audit_log(
            user=user, action="INVITE_QUOTATION",
            table_name="Orders", record_id=order_id,
            new_values={"supplier_ids": supplier_ids, "deadline": str(deadline)},
        )
        return requests_created

    @staticmethod
    @transaction.atomic
    def submit_bid(token_value: str, bid_data: dict, ip_address: str = None) -> Quotation:
        """
        NCC nộp báo giá qua Vendor Portal.
        Tự động quản lý version, khóa token sau khi submit.
        """
        token_obj = QuotationToken.objects.select_related("q_request__order", "q_request__supplier").get(
            token=token_value
        )
        q_request = token_obj.q_request

        items_data = bid_data["items"]
        total = sum(
            Decimal(str(item["quoted_unit_price"])) *
            Decimal(str(
                q_request.order.items.filter(order_item_id=item["order_item_id"])
                .values_list("qty_total_ordered", flat=True)
                .first() or 0
            ))
            for item in items_data
        )

        # Tạo hoặc cập nhật Quotation
        quotation, created = Quotation.objects.update_or_create(
            q_request=q_request,
            defaults={
                "supplier": q_request.supplier,
                "delivery_lead_time_days": bid_data["delivery_lead_time_days"],
                "payment_terms_note": bid_data.get("payment_terms_note"),
                "total_quote_amount": total,
            },
        )

        # Cập nhật QuotationItems
        QuotationItem.objects.filter(quotation=quotation).delete()
        q_items = [
            QuotationItem(
                quotation=quotation,
                order_item_id=item["order_item_id"],
                quoted_unit_price=item["quoted_unit_price"],
                supplier_note=item.get("supplier_note"),
            )
            for item in items_data
        ]
        QuotationItem.objects.bulk_create(q_items)

        # Lưu version
        last_version = quotation.versions.order_by("-version_number").first()
        next_version_num = (last_version.version_number + 1) if last_version else 1

        quotation.versions.filter(is_current=True).update(is_current=False)
        QuotationVersion.objects.create(
            quotation=quotation,
            version_number=next_version_num,
            is_current=True,
            snapshot_total_amount=total,
            snapshot_lead_time_days=bid_data["delivery_lead_time_days"],
            snapshot_payment_terms=bid_data.get("payment_terms_note"),
            snapshot_items_json=json.dumps(items_data, ensure_ascii=False, default=str),
            submitted_ip=ip_address,
            change_summary=f"Version {next_version_num}" if not created else "Báo giá lần đầu",
        )

        # Khóa token
        token_obj.is_used = True
        token_obj.used_at = timezone.now()
        token_obj.save(update_fields=["is_used", "used_at"])

        logger.info(
            "Bid submitted: quotation=%d supplier=%s version=%d",
            quotation.quotation_id, q_request.supplier.supplier_code, next_version_num
        )
        return quotation

    @staticmethod
    @transaction.atomic
    def select_quotation(user, quotation_id: int) -> Quotation:
        """Chọn phương án báo giá tối ưu."""
        quotation = Quotation.objects.select_related("q_request__order").get(
            quotation_id=quotation_id
        )
        order = quotation.q_request.order

        # Bỏ chọn tất cả quotation khác trong cùng order
        Quotation.objects.filter(
            q_request__order=order, is_selected=True
        ).update(is_selected=False)

        quotation.is_selected = True
        quotation.save(update_fields=["is_selected"])

        order.order_status = "QUOTE_CLOSED"
        order.save(update_fields=["order_status"])

        write_audit_log(
            user=user, action="SELECT_QUOTATION",
            table_name="Quotations", record_id=quotation_id,
            new_values={"selected": True},
        )
        return quotation
