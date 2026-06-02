from django.contrib import admin

from .models import Cart, CartPRItem, Order, OrderItem, OrderItemPRLink, OrderSupplier


class CartPRItemInline(admin.TabularInline):
    model = CartPRItem
    extra = 0
    readonly_fields = ["added_at"]


@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    list_display = ["cart_id", "cart_title", "buyer", "created_at"]
    inlines = [CartPRItemInline]


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0


class OrderSupplierInline(admin.TabularInline):
    model = OrderSupplier
    extra = 0


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ["order_code", "order_status", "buyer", "created_at"]
    list_filter = ["order_status"]
    search_fields = ["order_code"]
    inlines = [OrderItemInline, OrderSupplierInline]
