from django.urls import path

from .views import (
    ApprovalWorkflowListView,
    MaterialDetailView,
    MaterialListView,
    SupplierDetailView,
    SupplierListView,
    SystemConfigView,
)

# Prefix: /api/v2/master/
urlpatterns = [
    path("materials", MaterialListView.as_view(), name="material-list"),
    path("materials/<int:pk>", MaterialDetailView.as_view(), name="material-detail"),
    path("suppliers", SupplierListView.as_view(), name="supplier-list"),
    path("suppliers/<int:pk>", SupplierDetailView.as_view(), name="supplier-detail"),
    path("approval-workflows", ApprovalWorkflowListView.as_view(), name="approval-workflow-list"),
    path("configs", SystemConfigView.as_view(), name="system-config"),
]
