import datetime

from django.utils import timezone
from rest_framework import serializers

from .models import User


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
