"""
Celery async tasks gửi email.
Gọi từ services.py: send_quotation_invite_email.delay(...)
"""
import logging

from celery import shared_task

from infrastructure.emails.sender import EmailSender

logger = logging.getLogger("apps")


@shared_task(bind=True, max_retries=3, default_retry_delay=60, queue="emails")
def send_quotation_invite_email(
    self,
    supplier_email: str,
    supplier_name: str,
    order_code: str,
    portal_url: str,
    deadline: str,
) -> None:
    """
    Gửi email mời NCC báo giá kèm link portal.
    Retry tối đa 3 lần nếu SMTP lỗi.
    """
    try:
        EmailSender.send(
            to=supplier_email,
            subject=f"[Mời báo giá] {order_code} — Hạn nộp: {deadline}",
            template="quotation_invite",
            context={
                "supplier_name": supplier_name,
                "order_code": order_code,
                "portal_url": portal_url,
                "deadline": deadline,
            },
        )
        logger.info("Quotation invite sent to %s for order %s", supplier_email, order_code)
    except Exception as exc:
        logger.error("Failed to send quotation invite to %s: %s", supplier_email, exc)
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=3, default_retry_delay=30, queue="emails")
def send_approval_notification_email(
    self,
    recipient_email: str,
    recipient_name: str,
    document_type: str,
    document_code: str,
    action: str,
    comment: str = "",
) -> None:
    """
    Thông báo kết quả phê duyệt (APPROVED / REJECTED) cho người tạo chứng từ.
    """
    action_text = "được phê duyệt" if action == "APPROVED" else "bị từ chối"
    try:
        EmailSender.send(
            to=recipient_email,
            subject=f"[{document_type}] {document_code} đã {action_text}",
            template="approval_result",
            context={
                "recipient_name": recipient_name,
                "document_type": document_type,
                "document_code": document_code,
                "action_text": action_text,
                "comment": comment,
            },
        )
    except Exception as exc:
        logger.error("Failed to send approval notification to %s: %s", recipient_email, exc)
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=3, default_retry_delay=30, queue="emails")
def send_urgent_pr_notification_email(
    self,
    approver_email: str,
    approver_name: str,
    pr_code: str,
    requester_name: str,
    urgent_reason: str,
) -> None:
    """
    Push thông báo đến cấp phê duyệt khi có PR khẩn (URGENT).
    """
    try:
        EmailSender.send(
            to=approver_email,
            subject=f"[KHẨN] Yêu cầu mua hàng {pr_code} cần xử lý ngay",
            template="urgent_pr_alert",
            context={
                "approver_name": approver_name,
                "pr_code": pr_code,
                "requester_name": requester_name,
                "urgent_reason": urgent_reason,
            },
        )
    except Exception as exc:
        logger.error("Failed to send urgent PR notification to %s: %s", approver_email, exc)
        raise self.retry(exc=exc)
