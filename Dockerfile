# 使用多阶段构建来减小镜像大小
FROM alpine:3.18 AS builder

# 安装编译依赖
RUN apk add --no-cache \
    gcc \
    make \
    libc-dev \
    pcre-dev \
    zlib-dev \
    openssl-dev \
    linux-headers \
    curl \
    tar

# 创建工作目录
WORKDIR /tmp

# 复制源码文件（GitHub Actions会自动复制所有文件到工作目录）
COPY nginx.tar.gz rtmp.tar.gz ./

# 解压文件
RUN tar -xzf nginx.tar.gz && \
    tar -xzf rtmp.tar.gz && \
    rm -f nginx.tar.gz rtmp.tar.gz

# 编译 nginx
WORKDIR /tmp/nginx-1.20.2
RUN ./configure \
    --prefix=/usr/local/nginx \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-stream \
    --add-module=../nginx-rtmp-module \
    --with-cc-opt="-O2 -fPIE -fstack-protector-strong" \
    --with-ld-opt="-Wl,-z,relro,-z,now" && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install

# 创建运行阶段
FROM alpine:3.18

# 安装运行时的依赖
RUN apk add --no-cache \
    pcre \
    zlib \
    openssl \
    ca-certificates \
    libstdc++ \
    tzdata

# 创建非root用户
RUN addgroup -g 1000 nginx && \
    adduser -D -u 1000 -G nginx nginx

# 从构建阶段复制编译好的nginx
COPY --from=builder /usr/local/nginx /usr/local/nginx

# 创建必要的目录
RUN mkdir -p /var/log/nginx && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /tmp/nginx && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /tmp/nginx

# 复制配置文件
COPY nginx.conf /usr/local/nginx/conf/nginx.conf

# 复制启动脚本
COPY docker-entrypoint.sh /usr/local/bin/

# 设置权限
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    ln -sf /usr/local/nginx/sbin/nginx /usr/sbin/nginx

# 暴露端口
EXPOSE 1935  # RTMP默认端口
EXPOSE 8081    
EXPOSE 8088   

# 切换到非root用户
USER nginx

# 设置工作目录
WORKDIR /usr/local/nginx

# 设置健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD nginx -t || exit 1

# 设置入口点
ENTRYPOINT ["docker-entrypoint.sh"]

# 默认命令
CMD ["nginx", "-g", "daemon off;"]
