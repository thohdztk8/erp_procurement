from django.urls import path

from .views import (
    InviteQuotationView,
    QuotationCompareView,
    QuotationVersionHistoryView,
    SelectQuotationView,
    VendorPortalSubmitView,
)

# Prefix: /api/v2/quotation/ và /api/v2/vendor-portal/
urlpatterns = [
    # ── Nội bộ (JWT required) ─────────────────────────────────
    path("invite", InviteQuotationView.as_view(), name="quotation-invite"),
    path("compare/<int:order_id>", QuotationCompareView.as_view(), name="quotation-compare"),
    path("select", SelectQuotationView.as_view(), name="quotation-select"),
    path("<int:quotation_id>/versions", QuotationVersionHistoryView.as_view(), name="quotation-versions"),

    # ── Vendor Portal (Public — token SHA-256) ─────────────────
    path("submit-bid", VendorPortalSubmitView.as_view(), name="vendor-portal-submit"),
]
