from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination.standard import StandardResultsPagination
from core.permissions.rbac import require_permission

from .models import Inventory, WarehouseReceipt, WarehouseReturn
from .serializers import (
    InventorySerializer,
    ReceiptCreateSerializer,
    ReceiptSerializer,
    WarehouseReturnSerializer,
)
from .services import WarehouseService


class ReceiptCreateView(APIView):
    """POST /api/v2/warehouse/receipt"""
    permission_classes = [IsAuthenticated, require_permission("WH_RECEIPT")]

    def post(self, request):
        serializer = ReceiptCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            receipt = WarehouseService.create_receipt(request.user, serializer.validated_data)
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_422_UNPROCESSABLE_ENTITY)

        return Response(
            {
                "message": f"Phiếu nhập kho {receipt.receipt_code} đã được tạo.",
                "data": ReceiptSerializer(receipt).data,
            },
            status=status.HTTP_201_CREATED,
        )


class ReceiptDetailView(APIView):
    """GET /api/v2/warehouse/receipt/<id>"""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            receipt = WarehouseReceipt.objects.select_related("receiver").prefetch_related(
                "items"
            ).get(receipt_id=pk)
        except WarehouseReceipt.DoesNotExist:
            return Response({"detail": "Không tìm thấy phiếu nhập kho."}, status=404)
        return Response({"data": ReceiptSerializer(receipt).data})


class InventoryListView(APIView):
    """GET /api/v2/warehouse/inventory"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = Inventory.objects.select_related("material__category")

        keyword = request.query_params.get("keyword")
        if keyword:
            qs = qs.filter(material__material_name__icontains=keyword)

        low_stock = request.query_params.get("low_stock")
        if low_stock == "true":
            # Lọc hàng dưới ngưỡng tối thiểu
            from django.db.models import F as DjangoF
            qs = qs.filter(qty_available__lt=DjangoF("material__min_stock_level"))

        qs = qs.order_by("material__material_code")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(InventorySerializer(page, many=True).data)


class WarehouseReturnListView(APIView):
    """GET /api/v2/warehouse/returns"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = WarehouseReturn.objects.select_related("supplier").order_by("-created_at")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(WarehouseReturnSerializer(page, many=True).data)
