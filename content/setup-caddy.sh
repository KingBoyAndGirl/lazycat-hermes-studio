#!/bin/sh
# setup-caddy.sh - 初始化 Caddy 配置
set -e

CADDYFILE="/etc/caddy/Caddyfile"
SOURCE_CADDYFILE="/lzcapp/pkg/content/Caddyfile"

# 确保目录存在
mkdir -p /etc/caddy

# 复制 Caddyfile
if [ -f "$SOURCE_CADDYFILE" ]; then
    cp "$SOURCE_CADDYFILE" "$CADDYFILE"
    echo "[setup] Caddyfile copied to $CADDYFILE"
else
    echo "[setup] WARNING: $SOURCE_CADDYFILE not found"
fi

# 开发模式：使用自定义 Caddyfile
if [ "$DEV_ENABLE" = "1" ] && [ -f "/home/agent/.hermes-studio/Caddyfile" ]; then
    cp "/home/agent/.hermes-studio/Caddyfile" "$CADDYFILE"
    echo "[setup] Dev mode: using custom Caddyfile"
fi

echo "[setup] Caddy setup complete"
