"""
CartService: gom hàng từ PR đã duyệt, tạo Order, gán NCC.
"""
import logging
from collections import defaultdict
from decimal import Decimal

from django.db import transaction
from django.db.models import F

from core.utils.audit import write_audit_log
from core.utils.code_generator import generate_document_code

from .models import Cart, CartPRItem, Order, OrderItem, OrderItemPRLink, OrderSupplier

logger = logging.getLogger("apps")


class CartService:

    @staticmethod
    @transaction.atomic
    def add_items_to_cart(user, cart_title: str, pr_item_ids: list[int]) -> Cart:
        from apps.purchase_request.models import PRItem

        cart = Cart.objects.create(cart_title=cart_title, buyer=user)
        pr_items = PRItem.objects.filter(pr_item_id__in=pr_item_ids)

        cart_items = []
        for pi in pr_items:
            remaining = pi.qty_requested - pi.qty_ordered
            if remaining <= 0:
                continue
            cart_items.append(CartPRItem(cart=cart, pr_item=pi, qty_in_cart=remaining))

        CartPRItem.objects.bulk_create(cart_items)

        write_audit_log(
            user=user, event_type="CREATE",
            object_type="Carts", object_id=str(cart.cart_id),
            new_values={"cart_title": cart_title, "item_count": len(cart_items)},
        )
        logger.info("Cart %d created with %d items by %s", cart.cart_id, len(cart_items), user.username)
        return cart

    @staticmethod
    @transaction.atomic
    def update_cart_item(user, cart_id: int, pr_item_id: int, new_qty: Decimal) -> CartPRItem:
        from rest_framework.exceptions import ValidationError
        try:
            cart_item = CartPRItem.objects.get(cart_id=cart_id, pr_item_id=pr_item_id, cart__buyer=user)
        except CartPRItem.DoesNotExist:
            raise ValidationError("Không tìm thấy sản phẩm trong giỏ hàng.")
            
        pi = cart_item.pr_item
        remaining = pi.qty_requested - pi.qty_ordered
        if new_qty > remaining:
            raise ValidationError(f"Số lượng không được vượt quá số lượng chưa đặt ({remaining}).")
        if new_qty <= 0:
            raise ValidationError("Số lượng phải lớn hơn 0.")
            
        cart_item.qty_in_cart = new_qty
        cart_item.save(update_fields=["qty_in_cart"])
        
        write_audit_log(
            user=user, event_type="UPDATE",
            object_type="CartPRItems", object_id=f"{cart_id}-{pr_item_id}",
            new_values={"qty_in_cart": str(new_qty)},
        )
        return cart_item

    @staticmethod
    @transaction.atomic
    def remove_cart_item(user, cart_id: int, pr_item_id: int) -> None:
        from rest_framework.exceptions import ValidationError
        try:
            cart_item = CartPRItem.objects.get(cart_id=cart_id, pr_item_id=pr_item_id, cart__buyer=user)
        except CartPRItem.DoesNotExist:
            raise ValidationError("Không tìm thấy sản phẩm trong giỏ hàng.")
            
        cart_item.delete()
        
        write_audit_log(
            user=user, event_type="DELETE",
            object_type="CartPRItems", object_id=f"{cart_id}-{pr_item_id}",
            old_values={"deleted": True},
        )

    @staticmethod
    @transaction.atomic
    def create_order_from_cart(user, cart: Cart) -> Order:
        from apps.purchase_request.models import PRItem

        order_code = generate_document_code("ORD", Order, "order_code")
        order = Order.objects.create(order_code=order_code, buyer=user)

        grouped: dict = defaultdict(list)
        for ci in cart.cart_items.select_related("pr_item__material"):
            key = ci.pr_item.material_id or f"other:{ci.pr_item.material_name_other}"
            grouped[key].append(ci)

        for key, cart_items in grouped.items():
            first = cart_items[0].pr_item
            total_qty = sum(Decimal(str(ci.qty_in_cart)) for ci in cart_items)

            order_item = OrderItem.objects.create(
                order=order,
                material_id=first.material_id,
                material_name_other=first.material_name_other if not first.material_id else None,
                qty_total_ordered=total_qty,
            )

            links = []
            for ci in cart_items:
                links.append(OrderItemPRLink(
                    order_item=order_item,
                    pr_item=ci.pr_item,
                    qty_linked=ci.qty_in_cart,
                ))
                PRItem.objects.filter(pr_item_id=ci.pr_item.pr_item_id).update(
                    qty_ordered=F("qty_ordered") + ci.qty_in_cart
                )
            OrderItemPRLink.objects.bulk_create(links)

        write_audit_log(
            user=user, event_type="CREATE",
            object_type="Orders", object_id=str(order.order_id),
            new_values={"order_code": order_code, "from_cart": cart.cart_id},
        )
        logger.info("Order %s created from cart %d", order_code, cart.cart_id)
        return order

    @staticmethod
    @transaction.atomic
    def add_suppliers_to_order(order: Order, supplier_ids: list[int]) -> None:
        existing = set(order.order_suppliers.values_list("supplier_id", flat=True))
        new_ids = set(supplier_ids) - existing
        records = [OrderSupplier(order=order, supplier_id=sid) for sid in new_ids]
        OrderSupplier.objects.bulk_create(records)

    @staticmethod
    @transaction.atomic
    def update_order(user, order: Order, validated_data: dict) -> Order:
        from apps.purchase_request.models import PRItem
        from rest_framework.exceptions import ValidationError

        if order.order_status not in ["DRAFT", "QUOTING"]:
            raise ValidationError("Chỉ có thể sửa đơn hàng ở trạng thái Nháp hoặc Đang báo giá.")

        suppliers_data = validated_data.get("suppliers")
        items_data = validated_data.get("items")

        if suppliers_data is not None:
            # Delete old suppliers that don't have quotation
            # (In reality, if they have quotation, we shouldn't delete, but for now we just delete non-matching)
            # Find current supplier IDs
            current_sids = set(order.order_suppliers.values_list("supplier_id", flat=True))
            new_sids = {s["supplier_id"] for s in suppliers_data}
            
            # Remove ones not in new_sids
            to_remove = current_sids - new_sids
            if to_remove:
                order.order_suppliers.filter(supplier_id__in=to_remove).delete()
            
            # Add or update
            for s_data in suppliers_data:
                sid = s_data["supplier_id"]
                osup, created = OrderSupplier.objects.get_or_create(order=order, supplier_id=sid)
                if "custom_contact_name" in s_data:
                    osup.custom_contact_name = s_data["custom_contact_name"]
                if "custom_contact_email" in s_data:
                    osup.custom_contact_email = s_data["custom_contact_email"]
                if "custom_contact_phone" in s_data:
                    osup.custom_contact_phone = s_data["custom_contact_phone"]
                osup.save()

        if items_data is not None:
            # Map order_item_id -> order_item
            order_items_map = {item.order_item_id: item for item in order.items.prefetch_related("pr_links__pr_item")}
            for i_data in items_data:
                oi_id = i_data["order_item_id"]
                new_qty = Decimal(str(i_data["qty_total_ordered"]))
                if oi_id not in order_items_map:
                    continue
                oi = order_items_map[oi_id]
                old_qty = oi.qty_total_ordered
                if new_qty <= 0:
                    raise ValidationError("Số lượng phải lớn hơn 0.")
                    
                # Update PR items proportionally or sequentially.
                # For simplicity, we just distribute the difference.
                diff = new_qty - old_qty
                if diff != 0:
                    links = list(oi.pr_links.all())
                    # To increase, add to first link. To decrease, subtract from first link.
                    # This is naive but works for demonstration.
                    link = links[0]
                    pi = link.pr_item
                    
                    # Cập nhật ngược lại PRItem
                    if diff > 0 and diff > (pi.qty_requested - pi.qty_ordered):
                        raise ValidationError(f"Tăng số lượng vượt mức yêu cầu của PR {pi.pr.pr_code}.")
                        
                    link.qty_linked += diff
                    link.save()
                    
                    PRItem.objects.filter(pr_item_id=pi.pr_item_id).update(
                        qty_ordered=F("qty_ordered") + diff
                    )
                    
                    oi.qty_total_ordered = new_qty
                    oi.save(update_fields=["qty_total_ordered"])

        write_audit_log(
            user=user, event_type="UPDATE",
            object_type="Orders", object_id=str(order.order_id),
            new_values={"updated": True},
        )
        return order
