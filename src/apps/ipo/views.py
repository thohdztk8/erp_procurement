from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination.standard import StandardResultsPagination
from core.permissions.rbac import require_permission

from .models import IPO
from .serializers import IPOApproveSerializer, IPOCreateSerializer, IPODetailSerializer, IPOListSerializer
from .services import IPOService


class IPOCreateVersionView(APIView):
    """POST /api/v2/ipo/create-version"""
    permission_classes = [IsAuthenticated, require_permission("IPO_CREATE")]

    def post(self, request):
        serializer = IPOCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        ipo = IPOService.create_version(request.user, serializer.validated_data)
        return Response(
            {
                "message": f"IPO {ipo.ipo_code} v{ipo.version} đã được tạo.",
                "data": {"ipo_id": ipo.ipo_id, "ipo_code": ipo.ipo_code, "version": ipo.version},
            },
            status=status.HTTP_201_CREATED,
        )


class IPOSubmitView(APIView):
    """POST /api/v2/ipo/<id>/submit"""
    permission_classes = [IsAuthenticated, require_permission("IPO_CREATE")]

    def post(self, request, pk):
        try:
            ipo = IPO.objects.get(ipo_id=pk, is_latest=True)
        except IPO.DoesNotExist:
            return Response({"detail": "Không tìm thấy IPO."}, status=404)

        ipo = IPOService.submit_for_approval(ipo, request.user)
        return Response({"message": "IPO đã được nộp phê duyệt.", "data": {"ipo_status": ipo.ipo_status}})


class IPODetailView(APIView):
    """GET /api/v2/ipo/<id>"""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            ipo = IPO.objects.select_related("supplier", "buyer").prefetch_related(
                "items__order_item__material"
            ).get(ipo_id=pk)
        except IPO.DoesNotExist:
            return Response({"detail": "Không tìm thấy IPO."}, status=404)
        return Response({"data": IPODetailSerializer(ipo).data})


class IPOListView(APIView):
    """GET /api/v2/ipo/"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = IPO.objects.filter(is_latest=True).select_related("supplier", "buyer")

        ipo_status = request.query_params.get("status")
        if ipo_status:
            qs = qs.filter(ipo_status=ipo_status)

        qs = qs.order_by("-created_at")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(IPOListSerializer(page, many=True).data)


class IPOApproveView(APIView):
    """POST /api/v2/ipo/approve"""
    permission_classes = [IsAuthenticated, require_permission("IPO_APPROVE")]

    def post(self, request):
        serializer = IPOApproveSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            ipo = IPO.objects.get(
                ipo_id=serializer.validated_data["ipo_id"], is_latest=True
            )
        except IPO.DoesNotExist:
            return Response({"detail": "Không tìm thấy IPO."}, status=404)

        ipo = IPOService.process_approval(
            ipo=ipo,
            approver=request.user,
            action=serializer.validated_data["action"],
            comment=serializer.validated_data.get("comment", ""),
        )
        return Response({
            "message": "Xử lý phê duyệt IPO thành công.",
            "data": {"ipo_id": ipo.ipo_id, "ipo_status": ipo.ipo_status},
        })


class IPOPendingListView(APIView):
    """GET /api/v2/ipo/pending-list"""
    permission_classes = [IsAuthenticated, require_permission("IPO_APPROVE")]

    def get(self, request):
        from apps.master_data.models import ApprovalWorkflowStep
        from apps.purchase_request.models import DocumentApprovalProgress

        step_sequences = ApprovalWorkflowStep.objects.filter(
            role=request.user.role
        ).values_list("step_sequence", flat=True).distinct()

        pending_ids = DocumentApprovalProgress.objects.filter(
            document_type="IPO",
            approval_status="PENDING",
            step_sequence__in=step_sequences,
        ).values_list("document_id", flat=True)

        qs = IPO.objects.filter(
            ipo_id__in=pending_ids, ipo_status="PENDING", is_latest=True
        ).select_related("supplier", "buyer").order_by("-created_at")

        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(IPOListSerializer(page, many=True).data)
