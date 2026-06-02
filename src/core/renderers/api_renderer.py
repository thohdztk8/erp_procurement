"""
Custom JSON Renderer.
Bọc mọi response thành envelope chuẩn:
  Success:    { success, code, message, data, timestamp }
  Paginated:  { success, code, message, data: { items, pagination }, timestamp }
  Error:      đã được exception handler xử lý → pass-through
"""
import datetime

from rest_framework.renderers import JSONRenderer


def _now() -> str:
    return datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")


class ProcurementAPIRenderer(JSONRenderer):

    def render(self, data, accepted_media_type=None, renderer_context=None):
        renderer_context = renderer_context or {}
        response = renderer_context.get("response")

        if response is None:
            return super().render(data, accepted_media_type, renderer_context)

        code = response.status_code

        # Error envelope đã được exception handler xử lý (có key "success")
        if isinstance(data, dict) and "success" in data:
            return super().render(data, accepted_media_type, renderer_context)

        is_success = 200 <= code < 300

        if not is_success:
            # Trường hợp hiếm: DRF tạo error response mà không qua exception handler
            wrapped = {
                "success": False,
                "code": code,
                "message": "Đã xảy ra lỗi.",
                "errors": data,
                "timestamp": _now(),
            }
        elif isinstance(data, dict) and "results" in data and "count" in data:
            # Paginated response từ DRF
            request = renderer_context.get("request")
            page = int(request.query_params.get("page", 1)) if request else 1
            page_size = int(request.query_params.get("page_size", 20)) if request else 20
            total = data["count"]
            total_pages = -(-total // page_size)  # ceiling division

            wrapped = {
                "success": True,
                "code": code,
                "message": "Truy xuất danh sách thành công.",
                "data": {
                    "items": data["results"],
                    "pagination": {
                        "page": page,
                        "page_size": page_size,
                        "total_items": total,
                        "total_pages": total_pages,
                    },
                },
                "timestamp": _now(),
            }
        else:
            # Normal success response
            # View có thể trả về {"message": "...", "data": {...}}
            # hoặc trực tiếp object data
            if isinstance(data, dict) and "data" in data:
                payload = data["data"]
                msg = data.get("message", "Thao tác thành công.")
            else:
                payload = data
                msg = "Thao tác thành công."

            wrapped = {
                "success": True,
                "code": code,
                "message": msg,
                "data": payload,
                "timestamp": _now(),
            }

        return super().render(wrapped, accepted_media_type, renderer_context)
