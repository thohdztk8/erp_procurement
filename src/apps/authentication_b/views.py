import logging

from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken

from .serializers import LoginSerializer, UserProfileSerializer
from .services import AuthService

logger = logging.getLogger("apps")


class LoginView(APIView):
    """POST /api/v2/auth/login — Public"""
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = serializer.validated_data["user"]
        token_data = AuthService.issue_tokens(user)

        logger.info("Login success: %s", user.username)
        return Response(
            {"message": "Đăng nhập hệ thống thành công.", "data": token_data},
            status=status.HTTP_200_OK,
        )


class RefreshTokenView(APIView):
    """POST /api/v2/auth/refresh — Public"""
    permission_classes = [AllowAny]

    def post(self, request):
        raw = request.data.get("refresh_token")
        if not raw:
            return Response(
                {"detail": "Thiếu refresh_token."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            refresh = RefreshToken(raw)
            return Response(
                {
                    "message": "Token đã được làm mới.",
                    "data": {
                        "access_token": str(refresh.access_token),
                        "token_type": "Bearer",
                    },
                },
                status=status.HTTP_200_OK,
            )
        except TokenError as exc:
            logger.warning("Refresh token failed due to invalid/expired token: %s", exc, exc_info=True)
            return Response(
                {"detail": "refresh_token không hợp lệ hoặc đã hết hạn."},
                status=status.HTTP_401_UNAUTHORIZED,
            )


class LogoutView(APIView):
    """POST /api/v2/auth/logout — Yêu cầu đăng nhập"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        raw = request.data.get("refresh_token")
        if not raw:
            return Response(
                {"detail": "Thiếu refresh_token."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            RefreshToken(raw).blacklist()
            logger.info("Logout: %s", request.user.username)
            return Response(
                {"message": "Đăng xuất thành công."},
                status=status.HTTP_200_OK,
            )
        except TokenError as exc:
            logger.warning("Logout failed due to invalid refresh token: %s", exc, exc_info=True)
            return Response(
                {"detail": "refresh_token không hợp lệ hoặc đã hết hạn."},
                status=status.HTTP_400_BAD_REQUEST,
            )


class ProfileView(APIView):
    """GET /api/v2/auth/profile — Yêu cầu đăng nhập"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response({"data": serializer.data})


class HealthCheckView(APIView):
    """GET /api/v2/health/ — Public, dùng cho load balancer"""
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({"message": "OK", "data": {"status": "healthy"}})
