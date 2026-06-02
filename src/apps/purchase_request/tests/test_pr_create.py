"""
Unit tests: Tạo PR — validate cross-exclusion, urgent fields.
"""
import pytest
from rest_framework.exceptions import ValidationError

from apps.purchase_request.validators import (
    validate_material_cross_exclusion,
    validate_urgent_fields,
)


class TestMaterialCrossExclusion:
    def test_raises_when_both_empty(self):
        with pytest.raises(ValidationError):
            validate_material_cross_exclusion(None, None)

    def test_raises_when_both_filled(self):
        with pytest.raises(ValidationError):
            validate_material_cross_exclusion(1, "Vật tư tự do")

    def test_passes_with_material_id_only(self):
        validate_material_cross_exclusion(1, None)  # Không raise

    def test_passes_with_other_only(self):
        validate_material_cross_exclusion(None, "Vật tư tự do")  # Không raise


class TestUrgentFieldValidation:
    def test_normal_does_not_require_urgent_fields(self):
        validate_urgent_fields("NORMAL", None, None)  # Không raise

    def test_urgent_requires_both_fields(self):
        with pytest.raises(ValidationError) as exc_info:
            validate_urgent_fields("URGENT", None, None)
        errors = exc_info.value.detail
        assert "urgent_reason" in errors
        assert "urgency_impact" in errors

    def test_urgent_requires_urgency_impact(self):
        with pytest.raises(ValidationError) as exc_info:
            validate_urgent_fields("URGENT", "Lý do khẩn", None)
        errors = exc_info.value.detail
        assert "urgency_impact" in errors

    def test_urgent_passes_when_both_filled(self):
        validate_urgent_fields("URGENT", "Lý do khẩn", "Tác động sản xuất")  # Không raise
