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
    OrderUpdateSerializer,
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


class CartListView(APIView):
    """GET /api/v2/cart/"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = Cart.objects.filter(buyer=request.user).order_by("-created_at")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(CartSerializer(page, many=True).data)


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


class CartItemUpdateView(APIView):
    """PUT, DELETE /api/v2/cart/<cart_id>/items/<pr_item_id>"""
    permission_classes = [IsAuthenticated, require_permission("CART_CREATE")]

    def put(self, request, cart_id, pr_item_id):
        qty = request.data.get("qty_in_cart")
        if not qty:
            return Response({"detail": "Thiếu qty_in_cart."}, status=400)
            
        try:
            from decimal import Decimal
            new_qty = Decimal(str(qty))
        except:
            return Response({"detail": "qty_in_cart không hợp lệ."}, status=400)
            
        item = CartService.update_cart_item(request.user, cart_id, pr_item_id, new_qty)
        return Response({"message": "Cập nhật số lượng thành công.", "data": {"qty_in_cart": item.qty_in_cart}})

    def delete(self, request, cart_id, pr_item_id):
        CartService.remove_cart_item(request.user, cart_id, pr_item_id)
        return Response({"message": "Đã xóa sản phẩm khỏi giỏ hàng."})


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
        if request.user.has_permission("QUOTATION_SELECT"):
            qs = Order.objects.all()
        else:
            qs = Order.objects.filter(buyer=request.user)
        qs = qs.prefetch_related("items").order_by("-created_at")
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


class OrderUpdateView(APIView):
    """PUT /api/v2/cart/orders/<id>"""
    permission_classes = [IsAuthenticated, require_permission("ORDER_CREATE")]

    def put(self, request, pk):
        try:
            order = Order.objects.get(order_id=pk)
        except Order.DoesNotExist:
            return Response({"detail": "Không tìm thấy đơn hàng."}, status=404)

        serializer = OrderUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        CartService.update_order(request.user, order, serializer.validated_data)
        return Response({"message": "Cập nhật đơn hàng thành công."})


class OrderStatusUpdateView(APIView):
    """PUT /api/v2/cart/orders/<id>/status"""
    permission_classes = [IsAuthenticated, require_permission("ORDER_CREATE")]

    def put(self, request, pk):
        from rest_framework.exceptions import ValidationError
        from core.utils.audit import write_audit_log
        
        try:
            order = Order.objects.get(order_id=pk)
        except Order.DoesNotExist:
            return Response({"detail": "Không tìm thấy đơn hàng."}, status=404)

        new_status = request.data.get("status")
        valid_statuses = [
            "DRAFT", "QUOTING", "QUOTE_CLOSED", 
            "WAITING_DELIVERY", "PARTIAL_DELIVERED", "DELIVERED", 
            "CANCELLED"
        ]
        
        if new_status not in valid_statuses:
            raise ValidationError("Trạng thái không hợp lệ.")
            
        old_status = order.order_status
        order.order_status = new_status
        order.save(update_fields=["order_status"])
        
        write_audit_log(
            user=request.user, action="UPDATE_STATUS",
            table_name="Orders", record_id=order.order_id,
            old_values={"status": old_status},
            new_values={"status": new_status},
        )
        return Response({"message": f"Cập nhật trạng thái thành {new_status}."})
