from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import F

from core.permissions.rbac import require_permission
from apps.ipo.models import IPO
from apps.invoice.models import PaymentRequest
from apps.warehouse.models import Inventory


class DashboardSummaryView(APIView):
    """
    GET /api/v2/reports/dashboard-summary
    Trả về các chỉ số KPI tổng quan.
    """
    permission_classes = [IsAuthenticated, require_permission("REPORT_VIEW")]

    def get(self, request):
        # 1. ipos_in_progress: Đơn mua hàng PO đang được xử lý (PENDING và là bản mới nhất)
        ipos_in_progress = IPO.objects.filter(ipo_status="PENDING", is_latest=True).count()

        # 2. overdue_payments: Yêu cầu thanh toán trễ hạn (deadline trước thời điểm hiện tại và chưa thanh toán)
        now = timezone.now()
        overdue_payments = PaymentRequest.objects.filter(
            payment_deadline__lt=now
        ).exclude(req_status="PAID").count()

        # 3. low_stock_items: Số lượng vật tư trong kho có lượng tồn dưới mức tồn kho tối thiểu
        # Lọc distinct theo material_id để không đếm trùng cùng một loại vật tư ở các chi nhánh khác nhau
        low_stock_items = Inventory.objects.filter(
            qty_available__lt=F("material__min_stock_level")
        ).values("material_id").distinct().count()

        return Response({
            "ipos_in_progress": ipos_in_progress,
            "overdue_payments": overdue_payments,
            "low_stock_items": low_stock_items
        })
