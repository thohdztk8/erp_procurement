from django.urls import path

from .views import (
    HealthCheckView, LoginView, LogoutView, ProfileView, RefreshTokenView,
    UserListView, UserDetailView, UserDeactivateView, RoleListView, PermissionListView
)
# Prefix: /api/v2/auth/
urlpatterns = [
    path("login", LoginView.as_view(), name="auth-login"),
    path("refresh", RefreshTokenView.as_view(), name="auth-refresh"),
    path("logout", LogoutView.as_view(), name="auth-logout"),
    path("profile", ProfileView.as_view(), name="auth-profile"),
    path("users", UserListView.as_view(), name="user-list"),
    path("users/<int:pk>", UserDetailView.as_view(), name="user-detail"),
    path("users/<int:pk>/deactivate", UserDeactivateView.as_view(), name="user-deactivate"),
    path("roles", RoleListView.as_view(), name="role-list"),
    path("permissions", PermissionListView.as_view(), name="permission-list"),
]
# Health check — mount riêng ở /api/v2/health/
health_urlpatterns = [
    path("", HealthCheckView.as_view(), name="health-check"),
]
