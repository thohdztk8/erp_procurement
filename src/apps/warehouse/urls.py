from django.urls import path

from .views import InventoryListView, ReceiptCreateView, ReceiptDetailView, WarehouseReturnListView

# Prefix: /api/v2/warehouse/
urlpatterns = [
    path("receipt", ReceiptCreateView.as_view(), name="warehouse-receipt-create"),
    path("receipt/<int:pk>", ReceiptDetailView.as_view(), name="warehouse-receipt-detail"),
    path("inventory", InventoryListView.as_view(), name="warehouse-inventory"),
    path("returns", WarehouseReturnListView.as_view(), name="warehouse-returns"),
]
