# MediaMTX RTSP 服务器（自动发布视频流）

**注意：repo归档不再更新，迁移到[service-delivery-hub](https://github.com/xuopoj/service-delivery-hub/tree/main/live-media-server-rstp)**.

运行 MediaMTX 服务器并在启动时自动流式传输视频文件的 Docker 容器。

## 功能特性

- **MediaMTX 服务器**: 多协议流媒体服务器（RTSP、RTMP、HLS、WebRTC）
- **自动发布**: 启动时自动推流视频文件
- **Web 界面**: 基于浏览器的流媒体管理和观看界面
- **多协议支持**: 支持 RTSP、RTMP、HLS 和 WebRTC
- **API 和监控**: REST API 和 Prometheus 监控指标端点
- **多平台支持**: 支持 ARM64 和 AMD64 架构

## 快速开始

### 直接从Docker Hub下载

```bash
# 拉取最新版本（自动选择适合当前平台的镜像）
docker pull daminan/mediamtx-server:latest

# 或者拉取特定版本
docker pull daminan/mediamtx-server:v1.15.0

# 指定平台拉取（可选）
docker pull --platform linux/amd64 daminan/mediamtx-server:latest  # x86_64
docker pull --platform linux/arm64 daminan/mediamtx-server:latest  # ARM64
```

### 保存和传输镜像

```bash
# 方式1：保存当前平台镜像
docker pull daminan/mediamtx-server:latest                        # 自动选择当前平台
docker save -o mediamtx-server.tar daminan/mediamtx-server:latest # 保存单平台镜像
docker load -i mediamtx-server.tar                                # 加载镜像

# 方式2：保存特定平台镜像
docker pull --platform linux/amd64 daminan/mediamtx-server:latest # 拉取 x86_64 版本
docker save -o mediamtx-server-amd64.tar daminan/mediamtx-server:latest

docker pull --platform linux/arm64 daminan/mediamtx-server:latest # 拉取 ARM64 版本  
docker save -o mediamtx-server-arm64.tar daminan/mediamtx-server:latest

```


**重要说明**：
- 📱 `docker save` 只能保存**当前拉取的平台**镜像，不是多平台镜像
- 🔄 要在不同架构间传输，需要在源机器上拉取目标平台的镜像

### 本地构建（使用多平台构建脚本）

```bash
# 推荐：使用多平台构建脚本
./build-multiarch.sh              # 本地构建（当前平台）
./build-multiarch.sh --push       # 构建并推送多平台镜像（ARM64 + AMD64）

# 传统构建方式（仅当前平台，不推荐）
docker build -t mediamtx-server .
```

### 构建脚本功能

`build-multiarch.sh` 脚本提供以下功能：
- 🏗️ **自动多平台构建**: 支持 ARM64 和 AMD64 架构
- 🏷️ **双标签**: 同时创建版本标签（v1.15.0）和 latest 标签

### 运行容器

```bash
# 使用官方镜像运行（推荐）
docker run -d --name mediamtx \
  -p 8554:8554 \
  -p 1935:1935 \
  -p 8888:8888 \
  -p 8889:8889 \
  -p 9997:9997 \
  -p 9998:9998 \
  daminan/mediamtx-server:latest

# 使用本地构建的镜像运行
docker run -p 8554:8554 -p 1935:1935 -p 8888:8888 -p 8889:8889 -p 9997:9997 -p 9998:9998 mediamtx-server
```

### 访问视频流

运行后，容器会自动启动：
1. 在多个端口上运行 MediaMTX 服务器
2. MediaMTX 内部自动将 `steel_factory.mp4` 视频流式传输到 `rtsp://localhost:8554/live`

**可用的端点：**
- **RTSP 视频流**: `rtsp://localhost:8554/live`
- **Web 界面**: `http://localhost:8888`
- **HLS 视频流**: `http://localhost:8888/live`
- **WebRTC**: `http://localhost:8889`
- **REST API**: `http://localhost:9997`
- **监控指标**: `http://localhost:9998/metrics`

## 测试视频流

### 使用 FFplay
```bash
ffplay rtsp://localhost:8554/live
```

### 使用 VLC
```bash
vlc rtsp://localhost:8554/live
```

### Web 浏览器
打开 `http://localhost:8888` 并在 Web 界面中导航到视频流。

## 端口和服务

| 端口 | 协议 | 描述 |
|------|------|------|
| 8554 | RTSP | 实时流传输协议 |
| 1935 | RTMP | 实时消息传输协议 |
| 8888 | HTTP | HLS（HTTP 直播流）和 Web 界面 |
| 8889 | HTTP | WebRTC |
| 9997 | HTTP | REST API |
| 9998 | HTTP | 监控指标（Prometheus 格式）|

## 多平台架构支持

此镜像支持以下架构：

### 支持的平台
- **linux/amd64**: Intel 和 AMD x86_64 处理器
- **linux/arm64**: ARM64 处理器

### 平台检测和使用

```bash
# 检查当前系统架构
uname -i

# 查看镜像支持的平台
docker buildx imagetools inspect daminan/mediamtx-server:latest

# Docker 会自动选择匹配当前平台的镜像
docker pull daminan/mediamtx-server:latest
```

### 跨平台部署

```bash
# 使用多平台构建脚本（推荐）
./build-multiarch.sh              # 本地构建（当前平台）
./build-multiarch.sh --push       # 构建并推送多平台镜像到注册表

# 传统方式构建特定平台（可选）
docker buildx build --platform linux/amd64 -t mediamtx-server:amd64 .
docker buildx build --platform linux/arm64 -t mediamtx-server:arm64 .
```

