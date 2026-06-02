"""
Sinh và xác thực SHA-256 token cho Vendor Portal.
Token lưu DB dạng hex digest (64 ký tự), không thể reverse.
"""
import hashlib
import secrets


def generate_vendor_token() -> tuple[str, str]:
    """
    Tạo cặp (raw_token, hashed_token).
    - raw_token:    gửi cho NCC qua email (1 lần duy nhất, không lưu DB)
    - hashed_token: lưu vào QuotationTokens.token

    Returns:
        (raw_token, hashed_token)
    """
    raw = secrets.token_urlsafe(48)   # 64 ký tự URL-safe
    hashed = _hash(raw)
    return raw, hashed


def verify_vendor_token(raw_token: str, hashed_token: str) -> bool:
    """
    Kiểm tra raw token khớp với hash đã lưu DB.
    Dùng secrets.compare_digest để chống timing attack.
    """
    return secrets.compare_digest(_hash(raw_token), hashed_token)


def _hash(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()
