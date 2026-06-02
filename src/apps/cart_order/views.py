from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination.standard import StandardResultsPagination
from core.permissions.rbac import require_permission

from .models import Cart, Order
from .serializers import (
    AddItemsToCartSerializer,
    AddSuppliersSerializer,
    CartSerializer,
    OrderDetailSerializer,
    OrderListSerializer,
)
from .services import CartService


class CartAddItemsView(APIView):
    """POST /api/v2/cart/add-items"""
    permission_classes = [IsAuthenticated, require_permission("CART_CREATE")]

    def post(self, request):
        serializer = AddItemsToCartSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        cart = CartService.add_items_to_cart(
            user=request.user,
            cart_title=serializer.validated_data["cart_title"],
            pr_item_ids=serializer.validated_data["pr_item_ids"],
        )
        return Response(
            {"message": "Đã gom hàng vào giỏ.", "data": CartSerializer(cart).data},
            status=status.HTTP_201_CREATED,
        )


class CartDetailView(APIView):
    """GET /api/v2/cart/<id>"""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            cart = Cart.objects.prefetch_related("cart_items__pr_item__material").get(
                cart_id=pk, buyer=request.user
            )
        except Cart.DoesNotExist:
            return Response({"detail": "Không tìm thấy giỏ hàng."}, status=404)
        return Response({"data": CartSerializer(cart).data})


class OrderCreateView(APIView):
    """POST /api/v2/cart/<cart_id>/convert — Chuyển Cart thành Order"""
    permission_classes = [IsAuthenticated, require_permission("ORDER_CREATE")]

    def post(self, request, cart_id):
        try:
            cart = Cart.objects.get(cart_id=cart_id, buyer=request.user)
        except Cart.DoesNotExist:
            return Response({"detail": "Không tìm thấy giỏ hàng."}, status=404)

        order = CartService.create_order_from_cart(request.user, cart)
        return Response(
            {"message": f"Đơn hàng {order.order_code} đã được tạo.", "data": OrderDetailSerializer(order).data},
            status=status.HTTP_201_CREATED,
        )


class OrderListView(APIView):
    """GET /api/v2/cart/orders"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = Order.objects.filter(buyer=request.user).prefetch_related("items").order_by("-created_at")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(OrderListSerializer(page, many=True).data)


class OrderDetailView(APIView):
    """GET /api/v2/cart/orders/<id>"""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            order = Order.objects.prefetch_related(
                "items__material", "order_suppliers__supplier"
            ).get(order_id=pk)
        except Order.DoesNotExist:
            return Response({"detail": "Không tìm thấy đơn hàng."}, status=404)
        return Response({"data": OrderDetailSerializer(order).data})


class OrderAddSuppliersView(APIView):
    """POST /api/v2/cart/orders/<id>/suppliers"""
    permission_classes = [IsAuthenticated, require_permission("ORDER_CREATE")]

    def post(self, request, pk):
        try:
            order = Order.objects.get(order_id=pk)
        except Order.DoesNotExist:
            return Response({"detail": "Không tìm thấy đơn hàng."}, status=404)

        serializer = AddSuppliersSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        CartService.add_suppliers_to_order(order, serializer.validated_data["supplier_ids"])
        return Response({"message": "Đã thêm nhà cung cấp vào đơn hàng."})
