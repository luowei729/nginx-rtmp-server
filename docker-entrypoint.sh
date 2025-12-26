#!/bin/bash
set -e

echo "Starting nginx-rtmp server..."

# 检查 ffmpeg 是否存在
if [ -x "/usr/local/bin/ffmpeg" ]; then
    echo "✅ ffmpeg found at /usr/local/bin/ffmpeg"
    /usr/local/bin/ffmpeg -version | head -n 1
else
    echo "❌ ffmpeg not found or not executable"
    exit 1
fi

# 创建必要的目录
mkdir -p /tmp/hls
mkdir -p /tmp/dash
mkdir -p /rec
mkdir -p /rec/single

# 设置 PATH 环境变量，确保 nginx 能找到 ffmpeg
export PATH="/usr/local/bin:$PATH"
echo "PATH: $PATH"

# 测试nginx配置
echo "Testing nginx configuration..."
nginx -t

# 执行主命令
echo "Starting nginx..."
exec "$@"
