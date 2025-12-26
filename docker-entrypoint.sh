#!/bin/sh
set -e

echo "Starting nginx-rtmp server..."

# 创建必要的目录
mkdir -p /tmp/hls

# 测试nginx配置
echo "Testing nginx configuration..."
nginx -t

# 执行主命令
exec "$@"
