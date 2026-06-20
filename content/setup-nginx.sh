#!/bin/sh
# setup-nginx.sh - 初始化 Nginx 配置
set -e

NGINX_CONF="/etc/nginx/nginx.conf"
SOURCE_CONF="/lzcapp/pkg/content/nginx.conf"

# 确保目录存在
mkdir -p /etc/nginx

# 复制配置
if [ -f "$SOURCE_CONF" ]; then
    cp "$SOURCE_CONF" "$NGINX_CONF"
    echo "[setup] nginx.conf copied to $NGINX_CONF"
else
    echo "[setup] WARNING: $SOURCE_CONF not found"
fi

# 开发模式：使用自定义配置
if [ "$DEV_ENABLE" = "1" ] && [ -f "/home/agent/.hermes-studio/nginx.conf" ]; then
    cp "/home/agent/.hermes-studio/nginx.conf" "$NGINX_CONF"
    echo "[setup] Dev mode: using custom nginx.conf"
fi

echo "[setup] Nginx setup complete"
