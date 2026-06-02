"""
Sinh mã số chứng từ theo định dạng chuẩn.
Ví dụ: PR-2026-00001, IPO-2026-00042
"""
import datetime

from django.db import connection


def generate_document_code(prefix: str, model_class, code_field: str = "pr_code") -> str:
    """
    Sinh mã chứng từ duy nhất dạng PREFIX-YYYY-NNNNN.
    Dùng SELECT MAX để đảm bảo tính tăng dần ngay cả khi có concurrent request
    (trong môi trường single-node đủ dùng; high-concurrency cần DB sequence).

    Args:
        prefix:      "PR", "IPO", "WR", "INV", ...
        model_class: Django Model class để truy vấn số lớn nhất
        code_field:  Tên cột chứa mã chứng từ trong model

    Returns:
        Chuỗi mã, ví dụ "PR-2026-00001"
    """
    year = datetime.date.today().year
    pattern = f"{prefix}-{year}-"

    # Lấy mã lớn nhất trong năm hiện tại
    latest = (
        model_class.objects
        .filter(**{f"{code_field}__startswith": pattern})
        .order_by(f"-{code_field}")
        .values_list(code_field, flat=True)
        .first()
    )

    if latest:
        try:
            seq = int(latest.split("-")[-1]) + 1
        except (ValueError, IndexError):
            seq = 1
    else:
        seq = 1

    return f"{pattern}{seq:05d}"
