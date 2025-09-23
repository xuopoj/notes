FROM daminan/ubuntu-dev:22.04

# Build argument for MediaMTX version with default value
ARG MEDIAMTX_VERSION=v1.15.0

ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /app

# Update package list and install FFmpeg
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

    
# Download and install MediaMTX (multi-architecture support)
RUN set -ex; \
    ARCH=$(uname -m); \
    case "${ARCH}" in \
        x86_64) MEDIAMTX_ARCH='amd64' ;; \
        aarch64) MEDIAMTX_ARCH='arm64' ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac; \
    echo "Detected architecture: ${ARCH}, downloading MediaMTX ${MEDIAMTX_VERSION} for: ${MEDIAMTX_ARCH}"; \
    wget https://github.com/bluenviron/mediamtx/releases/download/${MEDIAMTX_VERSION}/mediamtx_${MEDIAMTX_VERSION}_linux_${MEDIAMTX_ARCH}.tar.gz && \
    tar -xzf mediamtx_${MEDIAMTX_VERSION}_linux_${MEDIAMTX_ARCH}.tar.gz && \
    mv mediamtx /usr/local/bin/ && \
    rm mediamtx_${MEDIAMTX_VERSION}_linux_${MEDIAMTX_ARCH}.tar.gz && \
    chmod +x /usr/local/bin/mediamtx


# Create videos and logs directories for mounted files
RUN mkdir -p /app/videos /app/logs

# Copy a sample video file (optional)
COPY steel_factory.mp4 /app/videos/

# Copy MediaMTX configuration file
COPY mediamtx.yml /app/mediamtx.yml

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose ports for RTSP, RTMP, HLS, WebRTC, API, and Metrics
EXPOSE 8554 1935 8888 8889 9997 9998

# Set the entrypoint to run the startup script
ENTRYPOINT ["/app/start.sh"]
