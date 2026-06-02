import logging

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination.standard import StandardResultsPagination
from core.permissions.rbac import require_permission

from .models import DocumentApprovalProgress, PurchaseRequisition
from .serializers import (
    ApprovalProgressSerializer,
    PRApproveSerializer,
    PRCreateSerializer,
    PRDetailSerializer,
    PRListSerializer,
)
from .services import PRService

logger = logging.getLogger("apps")


class PRCreateView(APIView):
    """POST /api/v2/pr/create"""
    permission_classes = [IsAuthenticated, require_permission("PR_CREATE")]

    def post(self, request):
        serializer = PRCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        pr = PRService.create_pr(request.user, serializer.validated_data)
        return Response(
            {"message": f"Đơn PR {pr.pr_code} đã được tạo.", "data": {"pr_id": pr.pr_id, "pr_code": pr.pr_code}},
            status=status.HTTP_201_CREATED,
        )


class PRSubmitView(APIView):
    """POST /api/v2/pr/<id>/submit — Nộp PR lên phê duyệt"""
    permission_classes = [IsAuthenticated, require_permission("PR_CREATE")]

    def post(self, request, pk):
        try:
            pr = PurchaseRequisition.objects.get(pr_id=pk, requester=request.user)
        except PurchaseRequisition.DoesNotExist:
            return Response({"detail": "Không tìm thấy đơn PR."}, status=404)

        pr = PRService.submit_for_approval(pr, request.user)
        return Response({"message": f"Đơn {pr.pr_code} đã được nộp phê duyệt.", "data": {"pr_status": pr.pr_status}})


class PRListView(APIView):
    """GET /api/v2/pr/"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = PurchaseRequisition.objects.select_related(
            "requester", "dept", "branch"
        ).prefetch_related("items")

        # Lọc theo role: dept head chỉ thấy PR của dept mình
        if not request.user.is_superuser:
            qs = qs.filter(dept=request.user.dept)

        pr_status = request.query_params.get("status")
        if pr_status:
            qs = qs.filter(pr_status=pr_status)

        priority = request.query_params.get("priority")
        if priority:
            qs = qs.filter(priority_level=priority)

        keyword = request.query_params.get("keyword")
        if keyword:
            qs = qs.filter(pr_code__icontains=keyword)

        qs = qs.order_by("-created_at")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(PRListSerializer(page, many=True).data)


class PRDetailView(APIView):
    """GET /api/v2/pr/<id>"""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            pr = PurchaseRequisition.objects.select_related(
                "requester", "dept", "branch"
            ).prefetch_related("items__material").get(pr_id=pk)
        except PurchaseRequisition.DoesNotExist:
            return Response({"detail": "Không tìm thấy đơn PR."}, status=404)

        approval_steps = DocumentApprovalProgress.objects.filter(
            document_type="PR", document_id=pk
        ).select_related("approver").order_by("step_sequence")

        return Response({
            "data": {
                "pr": PRDetailSerializer(pr).data,
                "approval_progress": ApprovalProgressSerializer(approval_steps, many=True).data,
            }
        })


class PRPendingListView(APIView):
    """GET /api/v2/pr/pending-list — Danh sách PR đang chờ TÔI duyệt"""
    permission_classes = [IsAuthenticated, require_permission("PR_APPROVE")]

    def get(self, request):
        # Tìm step_sequence role của user hiện tại
        from apps.master_data.models import ApprovalWorkflowStep

        step_sequences = ApprovalWorkflowStep.objects.filter(
            role=request.user.role
        ).values_list("step_sequence", flat=True).distinct()

        # PR đang PENDING và bước tương ứng chưa duyệt
        pending_pr_ids = DocumentApprovalProgress.objects.filter(
            document_type="PR",
            approval_status="PENDING",
            step_sequence__in=step_sequences,
        ).values_list("document_id", flat=True)

        qs = PurchaseRequisition.objects.filter(
            pr_id__in=pending_pr_ids,
            pr_status="PENDING",
        ).select_related("requester", "dept", "branch").order_by("-created_at")

        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(PRListSerializer(page, many=True).data)


class PRApproveView(APIView):
    """POST /api/v2/pr/approve"""
    permission_classes = [IsAuthenticated, require_permission("PR_APPROVE")]

    def post(self, request):
        serializer = PRApproveSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            pr = PurchaseRequisition.objects.get(
                pr_id=serializer.validated_data["pr_id"]
            )
        except PurchaseRequisition.DoesNotExist:
            return Response({"detail": "Không tìm thấy đơn PR."}, status=404)

        pr = PRService.process_approval(
            pr=pr,
            approver=request.user,
            action=serializer.validated_data["action"],
            comment=serializer.validated_data.get("comment", ""),
        )
        return Response({
            "message": "Xử lý phê duyệt thành công.",
            "data": {"pr_id": pr.pr_id, "pr_status": pr.pr_status},
        })
