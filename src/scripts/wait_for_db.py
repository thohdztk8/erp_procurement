"""
Poll MSSQL connection trước khi khởi động Django.
MSSQL mất 20-40s khởi động lần đầu nên cần retry.
"""
import os
import sys
import time

import pyodbc


def wait(max_retries: int = 30, interval: int = 3) -> None:
    host = os.getenv("DB_HOST", "db")
    port = os.getenv("DB_PORT", "1433")
    user = os.getenv("DB_USER", "sa")
    password = os.getenv("DB_PASSWORD", "")

    conn_str = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={host},{port};"
        f"UID={user};PWD={password};"
        "TrustServerCertificate=yes;"
    )

    for attempt in range(1, max_retries + 1):
        try:
            conn = pyodbc.connect(conn_str, timeout=3)
            conn.close()
            print(f"✅ MSSQL ready (attempt {attempt}/{max_retries})")
            return
        except pyodbc.Error as exc:
            print(f"   [{attempt}/{max_retries}] Not ready — {exc}")
            time.sleep(interval)

    print("❌ MSSQL không phản hồi sau tất cả các lần thử. Thoát.")
    sys.exit(1)


if __name__ == "__main__":
    wait()
