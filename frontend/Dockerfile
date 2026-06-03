# Stage 1: Build ứng dụng Vue 3 với Node
FROM node:20-alpine AS build-stage

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .
RUN npm run build

# Stage 2: Phục vụ ứng dụng bằng Nginx trên cổng 5173
FROM nginx:1.27-alpine AS production-stage

COPY --from=build-stage /app/dist /usr/share/nginx/html

# Thay đổi cấu hình cổng lắng nghe mặc định từ 80 thành 5173 để khớp với Nginx reverse proxy dùng chung
RUN sed -i 's/listen       80;/listen       5173;/g' /etc/nginx/conf.d/default.conf

EXPOSE 5173

CMD ["nginx", "-g", "daemon off;"]
