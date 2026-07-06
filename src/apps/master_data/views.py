from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination.standard import StandardResultsPagination
from core.permissions.rbac import HasPermissionCode, require_permission

from .models import ApprovalWorkflow, Material, Supplier, SystemConfig
from .serializers import (
    ApprovalWorkflowSerializer,
    MaterialSerializer,
    SupplierSerializer,
    SupplierContractPriceSerializer,
    SystemConfigSerializer,
)


class MaterialListView(APIView):
    """GET/POST /api/v2/master/materials"""
    permission_classes = [IsAuthenticated, HasPermissionCode]
    method_permissions = {
        "POST": "MATERIAL_CREATE"
    }

    def get(self, request):
        qs = Material.objects.filter(is_active=True).select_related("category")

        keyword = request.query_params.get("keyword")
        if keyword:
            qs = qs.filter(material_name__icontains=keyword)

        category_id = request.query_params.get("category_id")
        if category_id:
            qs = qs.filter(category_id=category_id)

        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        serializer = MaterialSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)

    def post(self, request):
        """
        Tạo vật tư mới.
        
        Parameters:
        - request (Request): Django REST Framework request object chứa body là thông tin vật tư.
        
        Returns:
        - Response: 201 Created với thông tin vật tư được tạo hoặc 403 Forbidden nếu không có quyền.
        """
        serializer = MaterialSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(
            {"success": True, "message": "Tạo vật tư mới thành công.", "data": serializer.data},
            status=status.HTTP_201_CREATED,
        )


class MaterialDetailView(APIView):
    """GET /api/v2/master/materials/<id>"""
    permission_classes = [IsAuthenticated, require_permission("CONFIG_VIEW")]

    def get(self, request, pk):
        try:
            obj = Material.objects.select_related("category").get(
                material_id=pk, is_active=True
            )
        except Material.DoesNotExist:
            return Response({"detail": "Không tìm thấy vật tư."}, status=404)
        return Response({"data": MaterialSerializer(obj).data})


class SupplierListView(APIView):
    """GET/POST /api/v2/master/suppliers"""
    permission_classes = [IsAuthenticated, HasPermissionCode]
    method_permissions = {
        "POST": "SUPPLIER_CREATE"
    }

    def get(self, request):
        qs = Supplier.objects.filter(is_active=True)

        keyword = request.query_params.get("keyword")
        if keyword:
            qs = qs.filter(supplier_name__icontains=keyword)

        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        serializer = SupplierSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)

    def post(self, request):
        """
        Tạo nhà cung cấp mới.
        
        Parameters:
        - request (Request): Django REST Framework request object chứa body là thông tin nhà cung cấp.
        
        Returns:
        - Response: 201 Created với thông tin nhà cung cấp được tạo hoặc 403 Forbidden nếu không có quyền.
        """
        serializer = SupplierSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(
            {"success": True, "message": "Tạo nhà cung cấp mới thành công.", "data": serializer.data},
            status=status.HTTP_201_CREATED,
        )


class SupplierDetailView(APIView):
    """GET /api/v2/master/suppliers/<id>"""
    permission_classes = [IsAuthenticated, require_permission("CONFIG_VIEW")]

    def get(self, request, pk):
        try:
            obj = Supplier.objects.get(supplier_id=pk, is_active=True)
        except Supplier.DoesNotExist:
            return Response({"detail": "Không tìm thấy nhà cung cấp."}, status=404)
        return Response({"data": SupplierSerializer(obj).data})


class ApprovalWorkflowListView(APIView):
    """GET /api/v2/master/approval-workflows"""
    permission_classes = [IsAuthenticated, require_permission("CONFIG_VIEW")]

    def get(self, request):
        qs = ApprovalWorkflow.objects.filter(is_active=True).prefetch_related("steps__role")
        return Response({"data": ApprovalWorkflowSerializer(qs, many=True).data})


class SystemConfigView(APIView):
    """GET /api/v2/master/configs"""
    permission_classes = [IsAuthenticated, require_permission("CONFIG_VIEW")]

    def get(self, request):
        qs = SystemConfig.objects.all()
        return Response({"data": SystemConfigSerializer(qs, many=True).data})


class SupplierContractPriceCreateView(APIView):
    """POST /api/v2/master/suppliers/<id>/contract-prices"""
    permission_classes = [IsAuthenticated, require_permission("SUPPLIER_EDIT")]

    def post(self, request, pk):
        try:
            supplier = Supplier.objects.get(supplier_id=pk, is_active=True)
        except Supplier.DoesNotExist:
            return Response({"detail": "Không tìm thấy nhà cung cấp."}, status=404)
        
        data = request.data.copy()
        data["supplier_id"] = supplier.supplier_id
        
        serializer = SupplierContractPriceSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        
        return Response({"message": "Tạo bảng giá khung thành công.", "data": serializer.data}, status=status.HTTP_201_CREATED)

