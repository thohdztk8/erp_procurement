"""
Unit tests: SHA-256 token generation & verification.
"""
from core.utils.token_generator import generate_vendor_token, verify_vendor_token


class TestVendorToken:
    def test_generates_different_tokens_each_time(self):
        raw1, _ = generate_vendor_token()
        raw2, _ = generate_vendor_token()
        assert raw1 != raw2

    def test_raw_and_hash_are_different(self):
        raw, hashed = generate_vendor_token()
        assert raw != hashed

    def test_hash_is_64_chars(self):
        """SHA-256 hex digest = 64 characters."""
        _, hashed = generate_vendor_token()
        assert len(hashed) == 64

    def test_verify_correct_token(self):
        raw, hashed = generate_vendor_token()
        assert verify_vendor_token(raw, hashed) is True

    def test_verify_wrong_token(self):
        raw, hashed = generate_vendor_token()
        assert verify_vendor_token("wrong-token", hashed) is False

    def test_verify_tampered_hash(self):
        raw, hashed = generate_vendor_token()
        tampered = hashed[:-4] + "aaaa"
        assert verify_vendor_token(raw, tampered) is False
