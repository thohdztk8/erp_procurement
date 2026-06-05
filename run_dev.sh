#!/bin/bash

# Script khởi chạy môi trường phát triển ERP Procurement.
# Tự động cấu hình file .env và chạy Docker Compose.

set -e

# Màu sắc hiển thị terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Định nghĩa đường dẫn file
ENV_FILE=".env"
ENV_EXAMPLE=".env.example"
DOCKER_COMPOSE_FILE="docker-compose.dev.yml"

echo -e "${GREEN}==> Khởi động môi trường phát triển (Development)...${NC}"

# 1. Kiểm tra sự tồn tại của file .env
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}[!] Không tìm thấy file $ENV_FILE. Đang sao chép từ $ENV_EXAMPLE...${NC}"
    if [ -f "$ENV_EXAMPLE" ]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        echo -e "${GREEN}[✓] Đã tạo thành công file $ENV_FILE. Vui lòng cập nhật các biến nếu cần thiết.${NC}"
    else
        echo -e "${RED}[✗] Lỗi: Không tìm thấy file $ENV_EXAMPLE để sao chép!${NC}"
        exit 1
    fi
fi

# 2. Kiểm tra docker command
DOCKER_CMD="docker compose"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[✗] Lỗi: Docker chưa được cài đặt trên hệ thống này. Vui lòng cài đặt Docker Desktop trước.${NC}"
    exit 1
fi

# 3. Chạy docker compose với các tham số truyền vào
if [ $# -eq 0 ]; then
    # Nếu không truyền tham số, mặc định chạy up --build
    echo -e "${GREEN}==> Thực hiện: $DOCKER_CMD -f $DOCKER_COMPOSE_FILE up --build${NC}"
    exec $DOCKER_CMD -f "$DOCKER_COMPOSE_FILE" up --build
else
    echo -e "${GREEN}==> Thực hiện: $DOCKER_CMD -f $DOCKER_COMPOSE_FILE $@${NC}"
    exec $DOCKER_CMD -f "$DOCKER_COMPOSE_FILE" "$@"
fi
