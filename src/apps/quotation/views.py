import logging

from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions.rbac import require_permission

from .models import Quotation, QuotationRequest, QuotationToken
from .serializers import (
    InviteQuotationSerializer,
    QuotationSerializer,
    QuotationVersionSerializer,
    SelectQuotationSerializer,
    VendorPortalSubmitSerializer,
)
from .services import QuotationService

logger = logging.getLogger("apps")


class InviteQuotationView(APIView):
    """POST /api/v2/quotation/invite"""
    permission_classes = [IsAuthenticated, require_permission("QUOTATION_INVITE")]

    def post(self, request):
        serializer = InviteQuotationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data

        requests = QuotationService.invite_suppliers(
            user=request.user,
            order_id=d["order_id"],
            supplier_ids=d["supplier_ids"],
            deadline=d["deadline_submission"],
        )
        return Response(
            {"message": f"Đã gửi mời báo giá tới {len(requests)} nhà cung cấp."},
            status=status.HTTP_201_CREATED,
        )


class VendorPortalSubmitView(APIView):
    """
    POST /api/v2/vendor-portal/submit-bid
    Public endpoint — NCC dùng token SHA-256, KHÔNG cần JWT.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VendorPortalSubmitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data

        ip = request.META.get("REMOTE_ADDR")
        quotation = QuotationService.submit_bid(
            token_value=d["token"],
            bid_data=d,
            ip_address=ip,
        )
        return Response(
            {"message": "Báo giá đã được ghi nhận thành công.", "data": {"quotation_id": quotation.quotation_id}},
            status=status.HTTP_201_CREATED,
        )


class QuotationCompareView(APIView):
    """GET /api/v2/quotation/compare/<order_id> — So sánh các báo giá"""
    permission_classes = [IsAuthenticated]

    def get(self, request, order_id):
        quotations = Quotation.objects.filter(
            q_request__order_id=order_id
        ).select_related("supplier").prefetch_related("items__order_item__material")

        return Response({
            "data": QuotationSerializer(quotations, many=True).data
        })


class QuotationVersionHistoryView(APIView):
    """GET /api/v2/quotation/<quotation_id>/versions"""
    permission_classes = [IsAuthenticated]

    def get(self, request, quotation_id):
        versions = QuotationVersionSerializer(
            data=None
        )
        try:
            q = Quotation.objects.get(quotation_id=quotation_id)
        except Quotation.DoesNotExist:
            return Response({"detail": "Không tìm thấy báo giá."}, status=404)

        versions = q.versions.order_by("version_number")
        return Response({"data": QuotationVersionSerializer(versions, many=True).data})


class SelectQuotationView(APIView):
    """POST /api/v2/quotation/select"""
    permission_classes = [IsAuthenticated, require_permission("QUOTATION_SELECT")]

    def post(self, request):
        serializer = SelectQuotationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            quotation = QuotationService.select_quotation(
                user=request.user,
                quotation_id=serializer.validated_data["quotation_id"],
            )
        except Quotation.DoesNotExist:
            return Response({"detail": "Không tìm thấy báo giá."}, status=404)

        return Response({
            "message": f"Đã chọn báo giá #{quotation.quotation_id} làm phương án tối ưu.",
            "data": {"quotation_id": quotation.quotation_id},
        })
