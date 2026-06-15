from django.urls import path

from .views import (
    InventoryListView, 
    ReceiptCreateView, 
    ReceiptDetailView, 
    WarehouseReturnListView,
    IssueCreateView,
    IssueListView,
    IssueConfirmView,
    WarehouseReturnCreateView,
)

# Prefix: /api/v2/warehouse/
urlpatterns = [
    path("receipt", ReceiptCreateView.as_view(), name="warehouse-receipt-create"),
    path("receipts", ReceiptCreateView.as_view(), name="warehouse-receipts-create"), # alias
    path("receipt/<int:pk>", ReceiptDetailView.as_view(), name="warehouse-receipt-detail"),
    path("inventory", InventoryListView.as_view(), name="warehouse-inventory"),
    path("return-orders", WarehouseReturnListView.as_view(), name="warehouse-returns"),
    path("return-orders/create", WarehouseReturnCreateView.as_view(), name="warehouse-return-create"),
    path("issues", IssueListView.as_view(), name="warehouse-issues"),
    path("issues/create", IssueCreateView.as_view(), name="warehouse-issue-create"),
    path("issues/<int:pk>/confirm-receipt", IssueConfirmView.as_view(), name="warehouse-issue-confirm"),
]
