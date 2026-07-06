import re
from rest_framework import serializers

def validate_vietnamese_phone(value):
    """
    Kiểm định định dạng số điện thoại Việt Nam hợp lệ.
    """
    if not value:
        return value
    
    phone_clean = str(value).strip()
    pattern = re.compile(r"^(0|\+84)(3|5|7|8|9|1[2689])([0-9]{8})$")
    if not pattern.match(phone_clean):
        raise serializers.ValidationError("Số điện thoại không đúng định dạng Việt Nam.")
    return phone_clean

def validate_strong_password(value):
    """
    Kiểm định độ mạnh của mật khẩu (độ dài >= 8, chứa hoa, thường và số).
    """
    if not value:
        return value

    if len(value) < 8:
        raise serializers.ValidationError("Mật khẩu phải dài tối thiểu 8 ký tự.")
    if not re.search(r"[A-Z]", value):
        raise serializers.ValidationError("Mật khẩu phải chứa ít nhất một chữ viết hoa.")
    if not re.search(r"[a-z]", value):
        raise serializers.ValidationError("Mật khẩu phải chứa ít nhất một chữ viết thường.")
    if not re.search(r"[0-9]", value):
        raise serializers.ValidationError("Mật khẩu phải chứa ít nhất một số.")
    return value
