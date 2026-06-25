import datetime

from django.utils import timezone
from rest_framework import serializers

from .models import User, Branch


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        username = attrs.get("username", "").strip()
        password = attrs.get("password", "")

        try:
            user = User.objects.select_related("role", "branch", "dept").get(
                username=username
            )
        except User.DoesNotExist:
            raise serializers.ValidationError(
                {"detail": "Tên đăng nhập hoặc mật khẩu không chính xác."}
            )

        # Kiểm tra tài khoản bị khóa
        if user.locked_until and user.locked_until > timezone.now():
            remaining = int((user.locked_until - timezone.now()).total_seconds() // 60)
            raise serializers.ValidationError(
                {"detail": f"Tài khoản đang bị khóa. Vui lòng thử lại sau {remaining} phút."}
            )

        if not user.is_active:
            raise serializers.ValidationError(
                {"detail": "Tài khoản đã bị vô hiệu hóa. Liên hệ quản trị viên."}
            )

        if not user.check_password(password):
            # Tăng fail count, khóa nếu vượt 5 lần
            user.login_fail_count += 1
            if user.login_fail_count >= 5:
                user.locked_until = timezone.now() + datetime.timedelta(minutes=15)
            user.save(update_fields=["login_fail_count", "locked_until"])
            raise serializers.ValidationError(
                {"detail": "Tên đăng nhập hoặc mật khẩu không chính xác."}
            )

        # Đăng nhập thành công → reset fail count
        if user.login_fail_count > 0:
            user.login_fail_count = 0
            user.locked_until = None
            user.save(update_fields=["login_fail_count", "locked_until"])

        attrs["user"] = user
        return attrs


class UserProfileSerializer(serializers.ModelSerializer):
    role_code = serializers.CharField(source="role.role_code", read_only=True)
    branch_name = serializers.CharField(source="branch.branch_name", read_only=True)
    dept_name = serializers.CharField(source="dept.dept_name", read_only=True)
    permissions = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "user_id", "username", "full_name", "email", "phone",
            "role_code", "branch_name", "dept_name", "permissions",
        ]
        read_only_fields = fields

    def get_permissions(self, obj) -> list[str]:
        return obj.get_permission_codes()


class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        from .models import Role
        model = Role
        fields = ["role_id", "role_code", "role_name", "description", "is_active"]


class PermissionSerializer(serializers.ModelSerializer):
    class Meta:
        from .models import Permission
        model = Permission
        fields = ["permission_id", "permission_code", "permission_name", "module_group"]


class UserSerializer(serializers.ModelSerializer):
    role_name = serializers.CharField(source="role.role_name", read_only=True)
    role_code = serializers.CharField(source="role.role_code", read_only=True)
    branch_name = serializers.CharField(source="branch.branch_name", read_only=True)
    dept_name = serializers.CharField(source="dept.dept_name", read_only=True)

    class Meta:
        model = User
        fields = [
            "user_id", "username", "full_name", "email", "phone",
            "role_id", "role_name", "role_code", "branch_id", "branch_name", 
            "dept_id", "dept_name", "is_active"
        ]


class UserCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False, allow_null=True)

    class Meta:
        model = User
        fields = [
            "username", "full_name", "email", "phone",
            "role", "branch", "dept", "password"
        ]
        
    def create(self, validated_data):
        password = validated_data.pop('password', None)
        user = User.objects.create(**validated_data)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save()
        return user


class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["full_name", "email", "phone", "role", "branch", "dept", "is_active"]


class BranchSerializer(serializers.ModelSerializer):
    """
    Serializer hiển thị thông tin chi tiết của chi nhánh (Branch).
    """
    class Meta:
        model = Branch
        fields = ["branch_id", "branch_code", "branch_name", "address", "is_active"]
