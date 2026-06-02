from django.urls import path

from .views import (
    PRApproveView,
    PRCreateView,
    PRDetailView,
    PRListView,
    PRPendingListView,
    PRSubmitView,
)

# Prefix: /api/v2/pr/
urlpatterns = [
    path("create", PRCreateView.as_view(), name="pr-create"),
    path("", PRListView.as_view(), name="pr-list"),
    path("<int:pk>", PRDetailView.as_view(), name="pr-detail"),
    path("<int:pk>/submit", PRSubmitView.as_view(), name="pr-submit"),
    path("pending-list", PRPendingListView.as_view(), name="pr-pending-list"),
    path("approve", PRApproveView.as_view(), name="pr-approve"),
]
