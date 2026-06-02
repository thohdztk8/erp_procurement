#!/bin/bash
set -e

echo "========================================"
echo "  Procurement System — Starting up"
echo "========================================"

echo "[1/3] Waiting for MSSQL..."
python /app/scripts/wait_for_db.py

echo "[2/3] Running migrations..."
# python manage.py migrate --noinput

echo "[3/3] Collecting static files..."
# python manage.py collectstatic --noinput --clear 2>/dev/null || true

echo "✅ Ready. Launching: $@"
exec "$@"
