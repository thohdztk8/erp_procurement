#!/bin/bash

# Script tự động xóa và khởi tạo lại Database ProcurementDB trong môi trường Docker.
# Định dạng log hiển thị có màu sắc để dễ theo dõi.

set -e

# Màu sắc hiển thị terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

ENV_FILE=".env"

echo -e "${YELLOW}==> Bắt đầu quy trình reset Database...${NC}"

# 1. Đọc mật khẩu DB_PASSWORD từ file .env
if [ -f "$ENV_FILE" ]; then
    # Lấy giá trị DB_PASSWORD từ .env, bỏ ký tự xuống dòng Windows nếu có
    DB_PASSWORD=$(grep -E "^DB_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '\r')
else
    echo -e "${RED}[✗] Lỗi: Không tìm thấy file cấu hình $ENV_FILE!${NC}"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}[✗] Lỗi: Không tìm thấy biến DB_PASSWORD trong file $ENV_FILE!${NC}"
    exit 1
fi

# Kiểm tra xem container procurement_db có đang chạy hay không
if ! docker ps | grep -q "procurement_db"; then
    echo -e "${RED}[✗] Lỗi: Container 'procurement_db' chưa khởi chạy. Hãy chạy 'sh run_dev.sh' trước!${NC}"
    exit 1
fi

# 2. Ngắt kết nối cũ, xóa DB hiện tại và tạo DB mới
echo -e "${YELLOW}[1/3] Đang xóa và tạo mới database trống 'ProcurementDB'...${NC}"
docker exec procurement_db /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$DB_PASSWORD" -C \
    -Q "ALTER DATABASE ProcurementDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE IF EXISTS ProcurementDB; CREATE DATABASE ProcurementDB COLLATE Vietnamese_CI_AS;"

echo -e "${GREEN}[✓] Đã tạo mới database trống.${NC}"

# 3. Chạy file schema db.sql
echo -e "${YELLOW}[2/3] Đang nạp cấu trúc bảng (schema) từ db.sql...${NC}"
docker exec procurement_db /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$DB_PASSWORD" -C -I \
    -i /docker-entrypoint-initdb.d/db.sql -b

echo -e "${GREEN}[✓] Nạp cấu trúc bảng thành công.${NC}"

# 4. Chạy file seed_master_data.sql
echo -e "${YELLOW}[3/3] Đang gieo dữ liệu mẫu (seed data) từ seed_master_data.sql...${NC}"
docker exec procurement_db /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$DB_PASSWORD" -C -I \
    -i /docker-entrypoint-initdb.d/seed_master_data.sql -b

echo -e "${GREEN}[✓] Gieo dữ liệu mẫu thành công.${NC}"
echo -e "${GREEN}==> RESET DATABASE THÀNH CÔNG!${NC}"
