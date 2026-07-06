from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination.standard import StandardResultsPagination
from core.permissions.rbac import require_permission

from .models import Inventory, WarehouseReceipt, WarehouseReturn, StockIssue
from .serializers import (
    InventorySerializer,
    ReceiptCreateSerializer,
    ReceiptSerializer,
    WarehouseReturnSerializer,
    IssueCreateSerializer,
    StockIssueSerializer,
    ReturnOrderCreateSerializer,
)
from .services import WarehouseService


class ReceiptCreateView(APIView):
    """POST /api/v2/warehouse/receipt"""
    permission_classes = [IsAuthenticated, require_permission("WH_RECEIPT_CREATE")]

    def get(self, request):
        qs = WarehouseReceipt.objects.select_related("warehouse_keeper").prefetch_related("items").order_by("-received_at")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(ReceiptSerializer(page, many=True).data)

    def post(self, request):
        serializer = ReceiptCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            receipt = WarehouseService.create_receipt(request.user, serializer.validated_data)
        except ValueError as exc:
            return Response(
                {"detail": "Không thể tạo phiếu nhập kho."},
                status=status.HTTP_422_UNPROCESSABLE_ENTITY,
            )

        return Response(
            {
                "message": f"Phiếu nhập kho {receipt.receipt_code} đã được tạo.",
                "data": ReceiptSerializer(receipt).data,
            },
            status=status.HTTP_201_CREATED,
        )


class ReceiptDetailView(APIView):
    """GET /api/v2/warehouse/receipt/<id>"""
    permission_classes = [IsAuthenticated, require_permission("WH_RECEIPT_CREATE")]

    def get(self, request, pk):
        try:
            receipt = WarehouseReceipt.objects.select_related("warehouse_keeper").prefetch_related(
                "items"
            ).get(receipt_id=pk)
        except WarehouseReceipt.DoesNotExist:
            return Response({"detail": "Không tìm thấy phiếu nhập kho."}, status=404)
        return Response({"data": ReceiptSerializer(receipt).data})


class InventoryListView(APIView):
    """GET /api/v2/warehouse/inventory"""
    permission_classes = [IsAuthenticated, require_permission("WH_INVENTORY_VIEW")]

    def get(self, request):
        qs = Inventory.objects.select_related("material", "branch")

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
    permission_classes = [IsAuthenticated, require_permission("WH_RETURN_CREATE")]

    def get(self, request):
        qs = WarehouseReturn.objects.select_related("supplier").order_by("-created_at")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(WarehouseReturnSerializer(page, many=True).data)

class WarehouseReturnCreateView(APIView):
    """POST /api/v2/warehouse/return-orders"""
    permission_classes = [IsAuthenticated, require_permission("WH_RETURN_CREATE")]

    def post(self, request):
        serializer = ReturnOrderCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            return_order = WarehouseService.create_return_order(request.user, serializer.validated_data)
        except ValueError as exc:
            return Response({"detail": "Không thể tạo phiếu hoàn trả. Vui lòng kiểm tra lại dữ liệu."}, status=400)

        return Response(
            {"message": "Tạo phiếu hoàn trả thành công", "data": WarehouseReturnSerializer(return_order).data}, 
            status=201
        )


class IssueCreateView(APIView):
    """POST /api/v2/warehouse/issues"""
    permission_classes = [IsAuthenticated, require_permission("WH_ISSUE_CREATE")]

    def post(self, request):
        serializer = IssueCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            issue = WarehouseService.create_issue(request.user, serializer.validated_data)
        except ValueError as exc:
            return Response({"detail": "Không thể tạo phiếu xuất kho. Vui lòng kiểm tra lại dữ liệu."}, status=400)

        return Response(
            {"message": "Xuất kho thành công", "data": StockIssueSerializer(issue).data}, 
            status=201
        )


class IssueListView(APIView):
    """GET /api/v2/warehouse/issues"""
    permission_classes = [IsAuthenticated, require_permission("WH_ISSUE_CREATE")]

    def get(self, request):
        qs = StockIssue.objects.select_related("warehouse_keeper", "receiver").prefetch_related("items").order_by("-issued_at")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(StockIssueSerializer(page, many=True).data)

class IssueConfirmView(APIView):
    """POST /api/v2/warehouse/issues/<id>/confirm-receipt"""
    permission_classes = [IsAuthenticated, require_permission("WH_ISSUE_CREATE")]

    def post(self, request, pk):
        try:
            issue = StockIssue.objects.get(issue_id=pk)
        except StockIssue.DoesNotExist:
            return Response({"detail": "Không tìm thấy phiếu xuất kho."}, status=404)
        
        # Cập nhật rating nếu có
        ratings = request.data.get("items_quality_rating", [])
        if ratings and len(ratings) > 0:
            rating_val = ratings[0].get("quality_rating", 5)
            # Cập nhật cho tất cả items của issue
            issue.items.update(quality_rating=rating_val)
            
        return Response({"message": "Đã xác nhận nhận hàng từ phiếu xuất kho."})
