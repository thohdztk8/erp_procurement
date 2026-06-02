"""
Unit tests: Phương trình cân bằng IQC.
qty_received = qty_passed + qty_failed
"""
import pytest
from rest_framework.exceptions import ValidationError

from apps.warehouse.serializers import ReceiptItemCreateSerializer


class TestIQCQtyBalance:
    def _serialize(self, data):
        s = ReceiptItemCreateSerializer(data=data)
        s.is_valid()
        return s

    def test_raises_when_balance_violated(self):
        s = self._serialize({
            "ipo_item_id": 1,
            "qty_received": "10.0000",
            "qty_passed": "8.0000",
            "qty_failed": "3.0000",   # 8+3 ≠ 10
        })
        assert not s.is_valid()
        assert "non_field_errors" in s.errors or any(
            "qty_received" in str(e) or "bằng" in str(e)
            for e in s.errors.values()
        )

    def test_raises_when_failed_without_photos(self):
        s = self._serialize({
            "ipo_item_id": 1,
            "qty_received": "10.0000",
            "qty_passed": "7.0000",
            "qty_failed": "3.0000",
            "photo_paths": [],         # Không có ảnh → lỗi
        })
        assert not s.is_valid()

    def test_passes_when_balance_correct_all_passed(self):
        s = self._serialize({
            "ipo_item_id": 1,
            "qty_received": "10.0000",
            "qty_passed": "10.0000",
            "qty_failed": "0.0000",
        })
        assert s.is_valid(), s.errors

    def test_passes_when_failed_with_photos(self):
        s = self._serialize({
            "ipo_item_id": 1,
            "qty_received": "10.0000",
            "qty_passed": "7.0000",
            "qty_failed": "3.0000",
            "photo_paths": ["/media/iqc/photo1.jpg", "/media/iqc/photo2.jpg"],
        })
        assert s.is_valid(), s.errors
