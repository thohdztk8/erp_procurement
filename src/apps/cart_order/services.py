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
