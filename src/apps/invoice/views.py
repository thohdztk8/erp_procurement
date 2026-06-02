from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination.standard import StandardResultsPagination
from core.permissions.rbac import require_permission

from .models import Invoice, PaymentRequest
from .serializers import (
    InvoiceCreateSerializer,
    InvoiceDetailSerializer,
    InvoiceListSerializer,
    OverrideSerializer,
    PaymentApproveSerializer,
    PaymentRequestSerializer,
    ThreeWayMatchingSerializer,
)
from .services import MatchingService, PaymentService


class InvoiceCreateView(APIView):
    """POST /api/v2/invoice/create"""
    permission_classes = [IsAuthenticated, require_permission("INV_CREATE")]

    def post(self, request):
        serializer = InvoiceCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        invoice = MatchingService.create_invoice(request.user, serializer.validated_data)
        return Response(
            {"message": f"Hóa đơn {invoice.invoice_code} đã được tạo.", "data": {"invoice_id": invoice.invoice_id}},
            status=status.HTTP_201_CREATED,
        )


class InvoiceListView(APIView):
    """GET /api/v2/invoice/"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = Invoice.objects.select_related("supplier").order_by("-created_at")

        inv_status = request.query_params.get("status")
        if inv_status:
            qs = qs.filter(invoice_status=inv_status)

        supplier_id = request.query_params.get("supplier_id")
        if supplier_id:
            qs = qs.filter(supplier_id=supplier_id)

        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(InvoiceListSerializer(page, many=True).data)


class InvoiceDetailView(APIView):
    """GET /api/v2/invoice/<id>"""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            invoice = Invoice.objects.select_related("supplier").prefetch_related("items").get(invoice_id=pk)
        except Invoice.DoesNotExist:
            return Response({"detail": "Không tìm thấy hóa đơn."}, status=404)

        data = InvoiceDetailSerializer(invoice).data

        # Kèm kết quả đối soát nếu đã chạy
        if hasattr(invoice, "matching_result"):
            data["matching"] = ThreeWayMatchingSerializer(invoice.matching_result).data

        return Response({"data": data})


class VerifyMatchingView(APIView):
    """POST /api/v2/invoice/verify-matching"""
    permission_classes = [IsAuthenticated, require_permission("INV_MATCHING")]

    def post(self, request):
        invoice_id = request.data.get("invoice_id")
        if not invoice_id:
            return Response({"detail": "Thiếu invoice_id."}, status=400)

        try:
            invoice = Invoice.objects.prefetch_related("items__ipo_item").get(invoice_id=invoice_id)
        except Invoice.DoesNotExist:
            return Response({"detail": "Không tìm thấy hóa đơn."}, status=404)

        matching = MatchingService.run_three_way_matching(invoice, request.user)
        return Response({
            "message": "Đối soát 3 chiều hoàn tất.",
            "data": ThreeWayMatchingSerializer(matching).data,
        })


class OverrideMatchingView(APIView):
    """POST /api/v2/invoice/<id>/override — Chỉ Ban Giám đốc"""
    permission_classes = [IsAuthenticated, require_permission("OVERRIDE_MATCHING")]

    def post(self, request, pk):
        serializer = OverrideSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            invoice = Invoice.objects.get(invoice_id=pk)
        except Invoice.DoesNotExist:
            return Response({"detail": "Không tìm thấy hóa đơn."}, status=404)

        matching = MatchingService.override_matching(
            invoice=invoice,
            user=request.user,
            override_note=serializer.validated_data["override_note"],
        )
        return Response({
            "message": "Override sai lệch thành công.",
            "data": ThreeWayMatchingSerializer(matching).data,
        })


class PaymentRequestCreateView(APIView):
    """POST /api/v2/payment/request"""
    permission_classes = [IsAuthenticated, require_permission("PAYMENT_CREATE")]

    def post(self, request):
        invoice_id = request.data.get("invoice_id")
        try:
            invoice = Invoice.objects.get(invoice_id=invoice_id)
        except Invoice.DoesNotExist:
            return Response({"detail": "Không tìm thấy hóa đơn."}, status=404)

        payment = PaymentService.create_payment_request(request.user, invoice)
        return Response(
            {"message": "Yêu cầu thanh toán đã được tạo.", "data": PaymentRequestSerializer(payment).data},
            status=status.HTTP_201_CREATED,
        )


class PaymentApproveView(APIView):
    """POST /api/v2/payment/approve"""
    permission_classes = [IsAuthenticated, require_permission("PAYMENT_APPROVE")]

    def post(self, request):
        serializer = PaymentApproveSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            payment = PaymentRequest.objects.select_related("invoice").get(
                payment_id=serializer.validated_data["payment_id"]
            )
        except PaymentRequest.DoesNotExist:
            return Response({"detail": "Không tìm thấy yêu cầu thanh toán."}, status=404)

        payment = PaymentService.approve_payment(
            user=request.user,
            payment=payment,
            action=serializer.validated_data["action"],
            note=serializer.validated_data.get("note", ""),
        )
        return Response({
            "message": "Xử lý yêu cầu thanh toán thành công.",
            "data": PaymentRequestSerializer(payment).data,
        })


class PaymentListView(APIView):
    """GET /api/v2/payment/"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = PaymentRequest.objects.select_related("invoice__supplier", "requested_by").order_by("-created_at")

        pay_status = request.query_params.get("status")
        if pay_status:
            qs = qs.filter(payment_status=pay_status)

        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(PaymentRequestSerializer(page, many=True).data)
