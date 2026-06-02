"""
RBAC Permission classes.
Kiểm tra permission_code đã được gán cho role của user hiện tại.
"""
from rest_framework.permissions import BasePermission


class HasPermissionCode(BasePermission):
    """
    Sử dụng trong view:
        permission_classes = [IsAuthenticated, HasPermissionCode]
        required_permission = "PR_APPROVE"

    Hoặc dùng factory:
        permission_classes = [IsAuthenticated, require_permission("PR_APPROVE")]
    """
    required_permission: str = ""

    def has_permission(self, request, view) -> bool:
        if not request.user or not request.user.is_authenticated:
            return False
        perm = getattr(view, "required_permission", self.required_permission)
        if not perm:
            return True  # Không khai báo → không kiểm tra
        return request.user.has_permission(perm)


def require_permission(code: str) -> type:
    """
    Factory tạo permission class động.
    Dùng: permission_classes = [IsAuthenticated, require_permission("IPO_CREATE")]
    """
    return type(
        f"Has_{code}",
        (HasPermissionCode,),
        {"required_permission": code},
    )
