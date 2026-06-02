"""
Middleware ghi request log cơ bản.
Các thao tác nghiệp vụ dùng write_audit_log() trong services.py.
"""
import logging
import time

logger = logging.getLogger("apps")


class AuditRequestMiddleware:
    """
    Log mọi API request: method, path, status, user, thời gian xử lý.
    Chỉ log các đường dẫn /api/ để tránh noise từ /admin/, /static/.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if not request.path.startswith("/api/"):
            return self.get_response(request)

        start = time.monotonic()
        response = self.get_response(request)
        elapsed_ms = int((time.monotonic() - start) * 1000)

        user = (
            request.user.username
            if hasattr(request, "user") and request.user.is_authenticated
            else "anonymous"
        )

        logger.info(
            "%s %s %s | user=%s | %dms",
            request.method,
            request.path,
            response.status_code,
            user,
            elapsed_ms,
        )
        return response
