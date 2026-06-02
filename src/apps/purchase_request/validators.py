"""
Validators cho Purchase Request.
Tách riêng để tái sử dụng trong serializer và service.
"""
from rest_framework import serializers


def validate_material_cross_exclusion(material_id, material_name_other):
    """
    Kiểm tra loại trừ chéo: phải có đúng 1 trong 2.
    - material_id: hàng trong danh mục chuẩn
    - material_name_other: hàng ngoài danh mục (text tự do)
    """
    has_material = bool(material_id)
    has_other = bool(material_name_other and str(material_name_other).strip())

    if not has_material and not has_other:
        raise serializers.ValidationError(
            "Dòng hàng phải chọn vật tư từ danh mục (material_id) "
            "HOẶC nhập tên tự do (material_name_other). Không được để trống cả hai."
        )
    if has_material and has_other:
        raise serializers.ValidationError(
            "Không được điền đồng thời material_id và material_name_other. Chỉ chọn một."
        )


def validate_urgent_fields(priority_level, urgent_reason, urgency_impact):
    """
    Nếu priority_level = URGENT thì urgent_reason và urgency_impact bắt buộc.
    """
    if priority_level == "URGENT":
        errors = {}
        if not urgent_reason or not str(urgent_reason).strip():
            errors["urgent_reason"] = "Bắt buộc nhập lý do khẩn khi priority_level = URGENT."
        if not urgency_impact or not str(urgency_impact).strip():
            errors["urgency_impact"] = "Bắt buộc nhập tác động vận hành khi priority_level = URGENT."
        if errors:
            raise serializers.ValidationError(errors)
