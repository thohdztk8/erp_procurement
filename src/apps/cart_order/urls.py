from django.urls import path

from .views import (
    CartAddItemsView,
    CartDetailView,
    OrderAddSuppliersView,
    OrderCreateView,
    OrderDetailView,
    OrderListView,
)

# Prefix: /api/v2/cart/
urlpatterns = [
    path("add-items", CartAddItemsView.as_view(), name="cart-add-items"),
    path("<int:pk>", CartDetailView.as_view(), name="cart-detail"),
    path("<int:cart_id>/convert", OrderCreateView.as_view(), name="cart-convert-to-order"),
    path("orders", OrderListView.as_view(), name="order-list"),
    path("orders/<int:pk>", OrderDetailView.as_view(), name="order-detail"),
    path("orders/<int:pk>/suppliers", OrderAddSuppliersView.as_view(), name="order-add-suppliers"),
]
