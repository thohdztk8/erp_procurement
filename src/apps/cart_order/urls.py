from django.urls import path

from .views import (
    CartAddItemsView,
    CartListView,
    CartDetailView,
    CartItemUpdateView,
    OrderAddSuppliersView,
    OrderCreateView,
    OrderDetailView,
    OrderListView,
    OrderUpdateView,
    OrderStatusUpdateView,
)

# Prefix: /api/v2/cart/
urlpatterns = [
    path("add-items", CartAddItemsView.as_view(), name="cart-add-items"),
    path("", CartListView.as_view(), name="cart-list"),
    path("<int:pk>", CartDetailView.as_view(), name="cart-detail"),
    path("<int:cart_id>/items/<int:pr_item_id>", CartItemUpdateView.as_view(), name="cart-item-update"),
    path("<int:cart_id>/convert", OrderCreateView.as_view(), name="cart-convert-to-order"),
    path("orders", OrderListView.as_view(), name="order-list"),
    path("orders/<int:pk>", OrderDetailView.as_view(), name="order-detail"),
    path("orders/<int:pk>/update", OrderUpdateView.as_view(), name="order-update"),
    path("orders/<int:pk>/status", OrderStatusUpdateView.as_view(), name="order-update-status"),
    path("orders/<int:pk>/suppliers", OrderAddSuppliersView.as_view(), name="order-add-suppliers"),
]
