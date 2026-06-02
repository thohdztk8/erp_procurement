"""
Module 1: Authentication & RBAC
Bảng: Branches, Departments, Roles, Permissions, RolePermissions, Users, AuditLogs
"""
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models


# ── Branches ──────────────────────────────────────────────────
class Branch(models.Model):
    branch_id = models.AutoField(primary_key=True)
    branch_code = models.CharField(max_length=20, unique=True)
    branch_name = models.CharField(max_length=200)
    address = models.CharField(max_length=500, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "Branches"

    def __str__(self):
        return self.branch_name


# ── Departments ───────────────────────────────────────────────
class Department(models.Model):
    dept_id = models.AutoField(primary_key=True)
    dept_code = models.CharField(max_length=20, unique=True)
    dept_name = models.CharField(max_length=200)
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, db_column="branch_id")
    parent_dept = models.ForeignKey(
        "self", on_delete=models.SET_NULL, null=True, blank=True, db_column="parent_dept_id"
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "Departments"

    def __str__(self):
        return self.dept_name


# ── Roles ─────────────────────────────────────────────────────
class Role(models.Model):
    role_id = models.AutoField(primary_key=True)
    role_code = models.CharField(max_length=50, unique=True)
    role_name = models.CharField(max_length=100)
    description = models.CharField(max_length=300, null=True, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "Roles"

    def __str__(self):
        return self.role_code


# ── Permissions ───────────────────────────────────────────────
class Permission(models.Model):
    permission_id = models.AutoField(primary_key=True)
    permission_code = models.CharField(max_length=100, unique=True)
    permission_name = models.CharField(max_length=150)
    module_group = models.CharField(max_length=50)

    class Meta:
        db_table = "Permissions"

    def __str__(self):
        return self.permission_code


# ── RolePermissions ───────────────────────────────────────────
class RolePermission(models.Model):
    role = models.ForeignKey(
        Role, on_delete=models.CASCADE, db_column="role_id", related_name="role_permissions"
    )
    permission = models.ForeignKey(
        Permission, on_delete=models.CASCADE, db_column="permission_id"
    )
    assigned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "RolePermissions"
        unique_together = ("role", "permission")


# ── Custom User Manager ───────────────────────────────────────
class UserManager(BaseUserManager):
    def create_user(self, username: str, password: str = None, **extra):
        if not username:
            raise ValueError("Username bắt buộc.")
        user = self.model(username=username, **extra)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, username: str, password: str = None, **extra):
        extra.setdefault("is_staff", True)
        extra.setdefault("is_superuser", True)
        return self.create_user(username, password, **extra)


# ── Users ─────────────────────────────────────────────────────
class User(AbstractBaseUser, PermissionsMixin):
    user_id = models.AutoField(primary_key=True)
    username = models.CharField(max_length=50, unique=True)
    # password_hash lưu bởi AbstractBaseUser qua field "password"
    full_name = models.CharField(max_length=150)
    email = models.EmailField(max_length=100, unique=True)
    phone = models.CharField(max_length=20, null=True, blank=True)
    branch = models.ForeignKey(
        Branch, on_delete=models.PROTECT, null=True, db_column="branch_id"
    )
    dept = models.ForeignKey(
        Department, on_delete=models.PROTECT, null=True, db_column="dept_id"
    )
    role = models.ForeignKey(
        Role, on_delete=models.PROTECT, null=True, db_column="role_id"
    )
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)    # Cho phép vào Django Admin
    login_fail_count = models.IntegerField(default=0)
    locked_until = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = "username"
    REQUIRED_FIELDS = ["email", "full_name"]

    objects = UserManager()

    class Meta:
        db_table = "Users"

    def __str__(self):
        return self.username

    def has_permission(self, permission_code: str) -> bool:
        """Kiểm tra user có permission_code qua role."""
        if self.is_superuser:
            return True
        if not self.role_id:
            return False
        return RolePermission.objects.filter(
            role_id=self.role_id,
            permission__permission_code=permission_code,
        ).exists()

    def get_permission_codes(self) -> list[str]:
        """Trả về danh sách tất cả permission codes của user."""
        if not self.role_id:
            return []
        return list(
            RolePermission.objects.filter(role_id=self.role_id)
            .values_list("permission__permission_code", flat=True)
        )


# ── AuditLogs ─────────────────────────────────────────────────
class AuditLog(models.Model):
    log_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, db_column="user_id"
    )
    action = models.CharField(max_length=50)        # CREATE | UPDATE | APPROVE | REJECT ...
    table_name = models.CharField(max_length=100)
    record_id = models.IntegerField(null=True, blank=True)
    old_values = models.TextField(null=True, blank=True)  # JSON string
    new_values = models.TextField(null=True, blank=True)  # JSON string
    ip_address = models.CharField(max_length=45, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "AuditLogs"
        # Tầng DB cấm UPDATE/DELETE bảng này — enforce qua DB trigger trong SQL
