from django.urls import path

from .views import (
    InvoiceCreateView,
    InvoiceDetailView,
    InvoiceListView,
    OverrideMatchingView,
    PaymentApproveView,
    PaymentListView,
    PaymentRequestCreateView,
    VerifyMatchingView,
)

# Prefix: /api/v2/invoice/ và /api/v2/payment/
urlpatterns = [
    # ── Invoice ────────────────────────────────────────────────
    path("create", InvoiceCreateView.as_view(), name="invoice-create"),
    path("", InvoiceListView.as_view(), name="invoice-list"),
    path("<int:pk>", InvoiceDetailView.as_view(), name="invoice-detail"),
    path("verify-matching", VerifyMatchingView.as_view(), name="invoice-verify-matching"),
    path("<int:pk>/override", OverrideMatchingView.as_view(), name="invoice-override"),

    # ── Payment ────────────────────────────────────────────────
    path("payment/request", PaymentRequestCreateView.as_view(), name="payment-request"),
    path("payment/approve", PaymentApproveView.as_view(), name="payment-approve"),
    path("payment/", PaymentListView.as_view(), name="payment-list"),
]
