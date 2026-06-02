"""
Email service wrapper.
Render template text đơn giản rồi gửi qua Django email backend.
"""
import logging

from django.core.mail import send_mail

logger = logging.getLogger("apps")

# Template text nội tuyến — production nên chuyển sang file .html
_TEMPLATES: dict[str, str] = {
    "quotation_invite": (
        "Kính gửi {supplier_name},\n\n"
        "Chúng tôi trân trọng mời quý công ty tham gia báo giá cho đơn hàng {order_code}.\n"
        "Vui lòng truy cập link sau để nộp báo giá:\n{portal_url}\n\n"
        "Hạn nộp: {deadline}\n\n"
        "Trân trọng."
    ),
    "approval_result": (
        "Kính gửi {recipient_name},\n\n"
        "Chứng từ {document_type} mã số {document_code} đã {action_text}.\n"
        "{comment}\n\n"
        "Vui lòng đăng nhập hệ thống để xem chi tiết.\n\n"
        "Trân trọng."
    ),
    "urgent_pr_alert": (
        "Kính gửi {approver_name},\n\n"
        "[KHẨN] Yêu cầu mua hàng {pr_code} do {requester_name} lập cần xử lý ngay.\n"
        "Lý do khẩn: {urgent_reason}\n\n"
        "Vui lòng đăng nhập hệ thống để phê duyệt.\n\n"
        "Trân trọng."
    ),
}


class EmailSender:
    @staticmethod
    def send(to: str, subject: str, template: str, context: dict) -> None:
        """
        Render template và gửi email.

        Args:
            to:       Địa chỉ email người nhận
            subject:  Tiêu đề email
            template: Key trong _TEMPLATES
            context:  Dict biến để format template
        """
        body_template = _TEMPLATES.get(template, "{message}")
        try:
            body = body_template.format(**context)
        except KeyError as exc:
            logger.warning("Email template '%s' missing key: %s", template, exc)
            body = str(context)

        send_mail(
            subject=subject,
            message=body,
            from_email=None,  # Dùng DEFAULT_FROM_EMAIL từ settings
            recipient_list=[to],
            fail_silently=False,
        )
