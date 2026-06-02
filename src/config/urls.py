"""
Root URL configuration.
Mỗi app tự quản lý urls.py của mình — file này chỉ làm nhiệm vụ include.
"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

API = "api/v2"

urlpatterns = [
    path("admin/", admin.site.urls),

    # ── Module 1: Authentication & RBAC ──────────────────────
    path(f"{API}/auth/", include("apps.authentication.urls")),

    # ── Module 2: Master Data ─────────────────────────────────
    path(f"{API}/master/", include("apps.master_data.urls")),

    # ── Module 3: Purchase Request ────────────────────────────
    path(f"{API}/pr/", include("apps.purchase_request.urls")),

    # ── Module 4: Cart & Order ────────────────────────────────
    path(f"{API}/cart/", include("apps.cart_order.urls")),

    # ── Module 5: Quotation & Vendor Portal ───────────────────
    path(f"{API}/quotation/", include("apps.quotation.urls")),
    path(f"{API}/vendor-portal/", include("apps.quotation.urls")),

    # ── Module 6: IPO ─────────────────────────────────────────
    path(f"{API}/ipo/", include("apps.ipo.urls")),

    # ── Module 7: Warehouse ───────────────────────────────────
    path(f"{API}/warehouse/", include("apps.warehouse.urls")),

    # ── Module 8: Invoice & Payment ───────────────────────────
    path(f"{API}/invoice/", include("apps.invoice.urls")),
    path(f"{API}/payment/", include("apps.invoice.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

    try:
        import debug_toolbar
        urlpatterns = [path("__debug__/", include(debug_toolbar.urls))] + urlpatterns
    except ImportError:
        pass
