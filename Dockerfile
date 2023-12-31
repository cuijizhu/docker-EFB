# 使用 Alpine Linux 的最新版本
FROM alpine:edge
MAINTAINER Roy Xiang <developer@royxiang.me>

# 设置环境变量
ENV LANG C.UTF-8

# 安装基础证书，以支持 HTTPS
RUN apk add --update --no-cache ca-certificates

# 安装运行时依赖
RUN set -ex \
    && apk add --no-cache --virtual .run-deps \
        ffmpeg \
        libmagic \
        python3 \
        py3-numpy \
        py3-pillow

# 安装用于获取 ehForwarderBot 的工具
RUN apk add --update --no-cache --virtual .fetch-deps \
        curl \
        tar

# 安装 jq 用于解析 JSON
RUN apk add --update --no-cache jq

# 下载最新版本的 ehForwarderBot
RUN set -ex \
    && echo "Fetching the latest tag of ehForwarderBot..." \
    && EFB_TAG_JSON=$(curl -s https://api.github.com/repos/blueset/ehForwarderBot/tags) \
    && echo "Tags JSON: $EFB_TAG_JSON" \
    && EFB_TAG_URL=$(echo $EFB_TAG_JSON | jq -r '.[0].tarball_url') \
    && echo "Downloading ehForwarderBot from $EFB_TAG_URL" \
    && curl -L -o EFB-latest.tar.gz $EFB_TAG_URL -v

# 解压并安装 ehForwarderBot
RUN set -ex \
    && mkdir -p /opt/ehForwarderBot/storage \
    && tar -xzf EFB-latest.tar.gz --strip-components=1 -C /opt/ehForwarderBot \
    && rm EFB-latest.tar.gz

# 清理 fetch 依赖并安装 Python 依赖
RUN apk del .fetch-deps \
    && pip3 install --no-cache-dir -r /opt/ehForwarderBot/requirements.txt

# 清理缓存
RUN rm -rf /root/.cache

# 设置工作目录
WORKDIR /opt/ehForwarderBot

# 设置容器启动时执行的命令
CMD ["python3", "main.py"]
