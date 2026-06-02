"""
Custom DRF exception handler.
Chuẩn hóa mọi lỗi thành envelope:
{
    "success": false,
    "code": <http_status>,
    "message": "<chuỗi đọc được>",
    "errors": { "field": ["..."] } | null,
    "trace_id": "req-xxxxxxxxxxxx",
    "timestamp": "2026-..."
}
"""
import datetime
import logging
import uuid

from django.core.exceptions import PermissionDenied as DjangoPermissionDenied
from django.core.exceptions import ValidationError as DjangoValidationError
from django.http import Http404
from rest_framework import status
from rest_framework.exceptions import (
    APIException,
    AuthenticationFailed,
    NotAuthenticated,
    NotFound,
    PermissionDenied,
    ValidationError,
)
from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_exception_handler

logger = logging.getLogger("apps")

_STATUS_MESSAGES = {
    400: "Yêu cầu không hợp lệ hoặc vi phạm logic nghiệp vụ.",
    401: "Phiên đăng nhập hết hạn hoặc token không hợp lệ. Vui lòng đăng nhập lại.",
    403: "Tài khoản không có quyền thực hiện thao tác này.",
    404: "Tài nguyên không tồn tại hoặc đã bị vô hiệu hóa.",
    409: "Dữ liệu bị trùng lặp. Vui lòng kiểm tra lại.",
    422: "Dữ liệu đầu vào không hợp lệ hoặc vi phạm ràng buộc nghiệp vụ.",
    429: "Quá nhiều yêu cầu. Vui lòng thử lại sau.",
    500: "Lỗi máy chủ. Vui lòng liên hệ quản trị viên.",
}


def _now() -> str:
    return datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")


def _trace() -> str:
    return f"req-{uuid.uuid4().hex[:12]}"


def procurement_exception_handler(exc, context) -> Response | None:
    # Chuyển Django native exceptions → DRF equivalents
    if isinstance(exc, Http404):
        exc = NotFound()
    elif isinstance(exc, DjangoPermissionDenied):
        exc = PermissionDenied()
    elif isinstance(exc, DjangoValidationError):
        detail = exc.message_dict if hasattr(exc, "message_dict") else str(exc)
        exc = ValidationError(detail=detail)

    response = drf_exception_handler(exc, context)

    if response is None:
        # Exception chưa được xử lý → 500
        logger.exception("Unhandled exception", exc_info=exc)
        body = {
            "success": False,
            "code": 500,
            "message": _STATUS_MESSAGES[500],
            "errors": None,
            "trace_id": _trace(),
            "timestamp": _now(),
        }
        return Response(body, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    code = response.status_code
    trace_id = _trace()
    errors = None
    message = _STATUS_MESSAGES.get(code, "Đã xảy ra lỗi.")

    data = response.data
    if isinstance(data, dict):
        if "detail" in data:
            message = str(data["detail"])
        else:
            errors = data
            # non_field_errors → đưa lên message, xóa khỏi errors
            if "non_field_errors" in errors:
                message = " ".join(str(e) for e in errors.pop("non_field_errors"))
    elif isinstance(data, list):
        message = " ".join(str(e) for e in data)

    response.data = {
        "success": False,
        "code": code,
        "message": message,
        "errors": errors,
        "trace_id": trace_id,
        "timestamp": _now(),
    }
    return response
