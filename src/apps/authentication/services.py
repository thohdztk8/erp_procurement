"""
AuthService: phát JWT sau khi xác thực thành công.
"""
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User


class AuthService:
    @staticmethod
    def issue_tokens(user: User) -> dict:
        """
        Phát access + refresh token cho user.
        Returns dict gồm token strings và thông tin user.
        """
        refresh = RefreshToken.for_user(user)
        access = refresh.access_token

        return {
            "access_token": str(access),
            "refresh_token": str(refresh),
            "token_type": "Bearer",
            "expires_in": int(access.lifetime.total_seconds()),
            "user": {
                "user_id": user.user_id,
                "username": user.username,
                "full_name": user.full_name,
                "email": user.email,
                "role_code": user.role.role_code if user.role else None,
                "branch_id": user.branch_id,
                "dept_id": user.dept_id,
                "permissions": user.get_permission_codes(),
            },
        }
