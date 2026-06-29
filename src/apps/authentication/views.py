import logging

from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken

from .serializers import (
    LoginSerializer, UserProfileSerializer, 
    UserSerializer, UserCreateSerializer, UserUpdateSerializer,
    RoleSerializer, PermissionSerializer, BranchSerializer
)
from .models import User, Role, Permission, Branch
from .services import AuthService
from core.pagination.standard import StandardResultsPagination

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
            logger.warning("Refresh token error: %s", str(exc))
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
            logger.warning("Logout token error for user %s: %s", request.user.username, str(exc))
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


class UserListView(APIView):
    """GET /api/v2/auth/users"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = User.objects.select_related("role", "branch", "dept").order_by("-created_at")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(UserSerializer(page, many=True).data)

    def post(self, request):
        """POST /api/v2/auth/users"""
        if not request.user.is_superuser and getattr(request.user.role, 'role_code', '') != 'ADMIN':
            return Response({"detail": "Forbidden"}, status=403)
        serializer = UserCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class UserDetailView(APIView):
    """PUT /api/v2/auth/users/<id>"""
    permission_classes = [IsAuthenticated]

    def put(self, request, pk):
        if not request.user.is_superuser and getattr(request.user.role, 'role_code', '') != 'ADMIN':
            return Response({"detail": "Forbidden"}, status=403)
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        
        serializer = UserUpdateSerializer(user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class UserDeactivateView(APIView):
    """PATCH /api/v2/auth/users/<id>/deactivate"""
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        if not request.user.is_superuser and getattr(request.user.role, 'role_code', '') != 'ADMIN':
            return Response({"detail": "Forbidden"}, status=403)
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        
        user.is_active = False
        user.save(update_fields=['is_active'])
        return Response({"message": "User deactivated."})


class RoleListView(APIView):
    """GET /api/v2/auth/roles"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = Role.objects.all().order_by("role_name")
        return Response({"items": RoleSerializer(qs, many=True).data})


class PermissionListView(APIView):
    """GET /api/v2/auth/permissions"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = Permission.objects.all().order_by("module_group", "permission_name")
        return Response({"items": PermissionSerializer(qs, many=True).data})


class BranchListView(APIView):
    """
    GET /api/v2/auth/branches
    Lấy danh sách các chi nhánh đang hoạt động trong hệ thống.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Xử lý yêu cầu GET trả về toàn bộ chi nhánh.
        
        Parameters:
            request (HttpRequest): Request object từ DRF.
            
        Returns:
            Response: Đối tượng chứa danh sách chi nhánh.
        """
        qs = Branch.objects.filter(is_active=True).order_by("branch_name")
        return Response(BranchSerializer(qs, many=True).data)
