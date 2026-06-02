"""
Helper ghi AuditLog tự động.
Dùng trong services.py khi có thao tác ghi/sửa dữ liệu.
"""
import json
import logging
from typing import Any

logger = logging.getLogger("apps")


def write_audit_log(
    *,
    user,
    action: str,
    table_name: str,
    record_id: int | None = None,
    old_values: dict | None = None,
    new_values: dict | None = None,
    request=None,
) -> None:
    """
    Ghi một bản ghi vào AuditLogs.

    Args:
        user:        User instance đang thực hiện hành động
        action:      "CREATE" | "UPDATE" | "DELETE" | "APPROVE" | "REJECT" | ...
        table_name:  Tên bảng DB bị tác động
        record_id:   PK của bản ghi bị tác động
        old_values:  Dict trạng thái cũ (trước khi sửa)
        new_values:  Dict trạng thái mới (sau khi sửa)
        request:     Django HttpRequest (để lấy IP)
    """
    # Import ở đây để tránh circular import
    from apps.authentication.models import AuditLog

    ip_address = None
    if request:
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        ip_address = (
            x_forwarded_for.split(",")[0].strip()
            if x_forwarded_for
            else request.META.get("REMOTE_ADDR")
        )

    try:
        AuditLog.objects.create(
            user=user,
            action=action,
            table_name=table_name,
            record_id=record_id,
            old_values=json.dumps(old_values, ensure_ascii=False, default=str)
            if old_values
            else None,
            new_values=json.dumps(new_values, ensure_ascii=False, default=str)
            if new_values
            else None,
            ip_address=ip_address,
        )
    except Exception as exc:
        # Audit log failure không được làm crash business logic
        logger.error("Failed to write audit log: %s", exc)
