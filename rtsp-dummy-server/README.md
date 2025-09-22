# MediaMTX RTSP 服务器（自动发布视频流）

运行 MediaMTX 服务器并在启动时自动流式传输视频文件的 Docker 容器。

## 功能特性

- **MediaMTX 服务器**: 多协议流媒体服务器（RTSP、RTMP、HLS、WebRTC）
- **自动发布**: 启动时自动推流视频文件
- **Web 界面**: 基于浏览器的流媒体管理和观看界面
- **多协议支持**: 支持 RTSP、RTMP、HLS 和 WebRTC
- **API 和监控**: REST API 和 Prometheus 监控指标端点

## 快速开始

### 直接从docker下载

```bash
docker pull daminan/mediamtx-server:latest
docker save -o mediamtx-server.tar daminan/mediamtx-server:latest
```

### 构建和运行

```bash
# 构建镜像
docker build -t mediamtx-server .

# 运行容器并暴露所有端口
docker run -p 8554:8554 -p 1935:1935 -p 8888:8888 -p 8889:8889 -p 9997:9997 -p 9998:9998 mediamtx-server
```

### 访问视频流

运行后，容器会自动启动：
1. 在多个端口上运行 MediaMTX 服务器
2. MediaMTX 内部自动将 `steel_factory.mp4` 视频流式传输到 `rtsp://localhost:8554/steel`

**可用的端点：**
- **RTSP 视频流**: `rtsp://localhost:8554/steel`
- **Web 界面**: `http://localhost:8888`
- **HLS 视频流**: `http://localhost:8888/steel`
- **WebRTC**: `http://localhost:8889`
- **REST API**: `http://localhost:9997`
- **监控指标**: `http://localhost:9998/metrics`

## 测试视频流

### 使用 FFplay
```bash
ffplay rtsp://localhost:8554/steel
```

### 使用 VLC
```bash
vlc rtsp://localhost:8554/steel
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