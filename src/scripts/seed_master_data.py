"""
Django management command: python manage.py seed_master_data
Chạy file SQL seed vào DB. Idempotent (dùng MERGE — chạy nhiều lần không lỗi).
"""
import os

from django.core.management.base import BaseCommand
from django.db import connection


class Command(BaseCommand):
    help = "Nạp Master Data ban đầu vào DB (Branches, Departments, Roles, Users, Materials...)"

    def handle(self, *args, **options):
        sql_path = os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "docs",
            "seed_master_data_v2_1.sql",
        )
        sql_path = os.path.abspath(sql_path)

        if not os.path.exists(sql_path):
            self.stderr.write(f"❌ Không tìm thấy file: {sql_path}")
            return

        self.stdout.write(f"📂 Đọc file: {sql_path}")

        with open(sql_path, encoding="utf-8") as f:
            raw_sql = f.read()

        # Tách theo GO (MSSQL batch separator)
        batches = [b.strip() for b in raw_sql.split("\nGO") if b.strip()]

        with connection.cursor() as cursor:
            for i, batch in enumerate(batches, 1):
                try:
                    cursor.execute(batch)
                    self.stdout.write(f"  ✓ Batch {i}/{len(batches)}")
                except Exception as exc:
                    self.stderr.write(f"  ✗ Batch {i} lỗi: {exc}")

        self.stdout.write(self.style.SUCCESS("✅ Seed master data hoàn tất."))
