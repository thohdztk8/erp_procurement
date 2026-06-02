from django.urls import path

from .views import HealthCheckView, LoginView, LogoutView, ProfileView, RefreshTokenView

# Prefix: /api/v2/auth/
urlpatterns = [
    path("login", LoginView.as_view(), name="auth-login"),
    path("refresh", RefreshTokenView.as_view(), name="auth-refresh"),
    path("logout", LogoutView.as_view(), name="auth-logout"),
    path("profile", ProfileView.as_view(), name="auth-profile"),
]

# Health check — mount riêng ở /api/v2/health/
health_urlpatterns = [
    path("", HealthCheckView.as_view(), name="health-check"),
]
