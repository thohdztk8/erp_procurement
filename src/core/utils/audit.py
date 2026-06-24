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
    action: str = None,
    table_name: str = None,
    record_id: Any = None,
    event_type: str = None,
    object_type: str = None,
    object_id: Any = None,
    old_values: dict | None = None,
    new_values: dict | None = None,
    request=None,
) -> None:
    """
    Ghi một bản ghi vào AuditLogs.

    Args:
        user:        User instance đang thực hiện hành động
        action:      "CREATE" | "UPDATE" | "DELETE" | "APPROVE" | "REJECT" | ... (tương thích ngược)
        table_name:  Tên bảng DB bị tác động (tương thích ngược)
        record_id:   PK của bản ghi bị tác động (tương thích ngược)
        event_type:  Mã hành động mới
        object_type: Loại đối tượng mới
        object_id:   Mã đối tượng mới
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

    # Ánh xạ mềm dẻo giữa cấu trúc cũ và cấu trúc mới
    final_event_type = event_type or action or "UNKNOWN"
    final_object_type = object_type or table_name or "UNKNOWN"
    final_object_id = str(object_id) if object_id is not None else (str(record_id) if record_id is not None else None)

    try:
        AuditLog.objects.create(
            user=user,
            event_type=final_event_type,
            object_type=final_object_type,
            object_id=final_object_id,
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
