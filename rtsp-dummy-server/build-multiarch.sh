#!/bin/bash

# Multi-architecture Docker build script for MediaMTX RTSP Server
# This script builds Docker images for multiple architectures using Docker Buildx

set -e

# Configuration
IMAGE_NAME="mediamtx-server"
MEDIAMTX_VERSION=v1.15.0
IMAGE_TAG=$MEDIAMTX_VERSION
PLATFORMS="linux/amd64,linux/arm64"

echo "==========================================="
echo "Multi-Architecture Docker Build Script"
echo "==========================================="
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "MediaMTX Version: ${MEDIAMTX_VERSION}"
echo "Platforms: ${PLATFORMS}"
echo "==========================================="

# Check if Docker Buildx is available
if ! docker buildx version > /dev/null 2>&1; then
    echo "Error: Docker Buildx is not available. Please install Docker Desktop or enable Buildx."
    exit 1
fi

# Create a new builder instance (if not exists)
BUILDER_NAME="multiarch-builder"
if ! docker buildx ls | grep -q "${BUILDER_NAME}"; then
    echo "Creating new buildx builder: ${BUILDER_NAME}"
    docker buildx create --name ${BUILDER_NAME} --driver docker-container --bootstrap
fi

# Use the builder
echo "Using buildx builder: ${BUILDER_NAME}"
docker buildx use ${BUILDER_NAME}

# Build and push multi-architecture image
echo "Building multi-architecture image..."
docker buildx build \
    --platform ${PLATFORMS} \
    --build-arg MEDIAMTX_VERSION=${MEDIAMTX_VERSION} \
    --tag ${IMAGE_NAME}:${IMAGE_TAG} \
    --tag ${IMAGE_NAME}:latest \
    .

echo "==========================================="
echo "Multi-architecture build completed!"
echo "==========================================="
echo "Built platforms: ${PLATFORMS}"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "To run on different architectures:"
echo "  AMD64: docker run --platform linux/amd64 ${IMAGE_NAME}:${IMAGE_TAG}"
echo "  ARM64: docker run --platform linux/arm64 ${IMAGE_NAME}:${IMAGE_TAG}"
echo "==========================================="
