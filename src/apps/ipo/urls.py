from django.urls import path

from .views import (
    IPOApproveView,
    IPOCreateVersionView,
    IPODetailView,
    IPOListView,
    IPOPendingListView,
    IPOSubmitView,
)

# Prefix: /api/v2/ipo/
urlpatterns = [
    path("create-version", IPOCreateVersionView.as_view(), name="ipo-create-version"),
    path("", IPOListView.as_view(), name="ipo-list"),
    path("<int:pk>", IPODetailView.as_view(), name="ipo-detail"),
    path("<int:pk>/submit", IPOSubmitView.as_view(), name="ipo-submit"),
    path("pending-list", IPOPendingListView.as_view(), name="ipo-pending-list"),
    path("approve", IPOApproveView.as_view(), name="ipo-approve"),
]
