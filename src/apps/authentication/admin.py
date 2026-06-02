from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import AuditLog, Branch, Department, Permission, Role, RolePermission, User


@admin.register(Branch)
class BranchAdmin(admin.ModelAdmin):
    list_display = ["branch_code", "branch_name", "is_active", "created_at"]
    list_filter = ["is_active"]
    search_fields = ["branch_code", "branch_name"]


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ["dept_code", "dept_name", "branch", "is_active"]
    list_filter = ["branch", "is_active"]
    search_fields = ["dept_code", "dept_name"]


@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display = ["role_code", "role_name", "is_active"]
    search_fields = ["role_code", "role_name"]


@admin.register(Permission)
class PermissionAdmin(admin.ModelAdmin):
    list_display = ["permission_code", "permission_name", "module_group"]
    list_filter = ["module_group"]
    search_fields = ["permission_code"]


@admin.register(RolePermission)
class RolePermissionAdmin(admin.ModelAdmin):
    list_display = ["role", "permission", "assigned_at"]
    list_filter = ["role"]


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ["username", "full_name", "email", "role", "branch", "is_active"]
    list_filter = ["role", "branch", "is_active"]
    search_fields = ["username", "full_name", "email"]
    ordering = ["username"]
    fieldsets = (
        (None, {"fields": ("username", "password")}),
        ("Thông tin", {"fields": ("full_name", "email", "phone")}),
        ("Phân quyền", {"fields": ("role", "branch", "dept", "is_active", "is_staff", "is_superuser")}),
        ("Bảo mật", {"fields": ("login_fail_count", "locked_until")}),
    )
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("username", "full_name", "email", "password1", "password2",
                       "role", "branch", "dept"),
        }),
    )


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ["audit_id", "user", "event_type", "object_type", "object_id", "created_at"]
    list_filter = ["event_type", "object_type"]
    search_fields = ["object_type", "user__username"]
    readonly_fields = ["audit_id", "user", "event_type", "object_type", "object_id",
                       "old_values", "new_values", "ip_address", "created_at"]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


from .models import Notification

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ["notification_id", "recipient", "notification_type", "is_read", "created_at"]
    list_filter = ["notification_type", "is_read"]
    search_fields = ["recipient__username", "title"]
    readonly_fields = ["created_at"]
