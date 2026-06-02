"""
Unit tests: Logic tính toán đối soát 3 chiều.
"""
from decimal import Decimal


class TestThreeWayMatchingCalculation:
    """Test pure calculation logic — không cần DB."""

    def _calc(self, qty_invoice, qty_received_passed, price_invoice, price_ipo):
        qty_diff = Decimal(str(qty_invoice)) - Decimal(str(qty_received_passed))
        price_diff = Decimal(str(price_invoice)) - Decimal(str(price_ipo))
        is_error = (qty_diff != 0) or (price_diff != 0)
        return qty_diff, price_diff, is_error

    def test_matched_no_diff(self):
        qty_diff, price_diff, is_error = self._calc(10, 10, 100, 100)
        assert qty_diff == 0
        assert price_diff == 0
        assert is_error is False

    def test_qty_diff_detected(self):
        qty_diff, price_diff, is_error = self._calc(10, 8, 100, 100)
        assert qty_diff == Decimal("2")
        assert is_error is True

    def test_price_diff_detected(self):
        qty_diff, price_diff, is_error = self._calc(10, 10, 105, 100)
        assert price_diff == Decimal("5")
        assert is_error is True

    def test_negative_qty_diff(self):
        """NCC giao ít hơn hóa đơn ghi."""
        qty_diff, _, is_error = self._calc(10, 12, 100, 100)
        assert qty_diff == Decimal("-2")
        assert is_error is True

    def test_both_diffs(self):
        qty_diff, price_diff, is_error = self._calc(10, 9, 110, 100)
        assert qty_diff == Decimal("1")
        assert price_diff == Decimal("10")
        assert is_error is True
