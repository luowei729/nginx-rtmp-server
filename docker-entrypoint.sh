#!/bin/sh
set -e

# 创建必要的目录
mkdir -p /tmp/hls

# 设置权限
chown -R nginx:nginx /tmp/hls 2>/dev/null || true

# 测试nginx配置
echo "Testing nginx configuration..."
nginx -t

# 执行主命令
exec "$@"
