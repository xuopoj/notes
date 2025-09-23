#!/bin/bash

# Multi-architecture Docker build script for MediaMTX RTSP Server
# This script builds Docker images for multiple architectures using Docker Buildx
# Usage: ./build-multiarch.sh [--push]
# Example: ./build-multiarch.sh --push

set -e

# Parse arguments
PUSH_FLAG=""
if [[ "$1" == "--push" ]]; then
    PUSH_FLAG="--push"
fi

# Configuration
ORGANIZATION="daminan"
IMAGE_NAME="mediamtx-server"
MEDIAMTX_VERSION=v1.15.0
IMAGE_TAG=$MEDIAMTX_VERSION
PLATFORMS="linux/amd64,linux/arm64"
FULL_IMAGE_NAME="${ORGANIZATION}/${IMAGE_NAME}"

echo "==========================================="
echo "Multi-Architecture Docker Build Script"
echo "==========================================="
echo "Organization: ${ORGANIZATION}"
echo "Image: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
echo "MediaMTX Version: ${MEDIAMTX_VERSION}"
echo "Platforms: ${PLATFORMS}"
if [[ -n "$PUSH_FLAG" ]]; then
    echo "Mode: Build and push to registry"
else
    echo "Mode: Build locally (single platform only)"
fi
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

# Build multi-architecture image
echo "Building multi-architecture image..."

if [[ -n "$PUSH_FLAG" ]]; then
    echo "Building and pushing to registry for true multi-platform support..."
    docker buildx build \
        --platform ${PLATFORMS} \
        --build-arg MEDIAMTX_VERSION=${MEDIAMTX_VERSION} \
        --tag ${FULL_IMAGE_NAME}:${IMAGE_TAG} \
        --tag ${FULL_IMAGE_NAME}:latest \
        --push \
        .
else
    echo "Building locally (will only build for current platform)..."
    echo "Note: To build for both AMD64 and ARM64, use: ./build-multiarch.sh --push"
    docker buildx build \
        --platform ${PLATFORMS} \
        --build-arg MEDIAMTX_VERSION=${MEDIAMTX_VERSION} \
        --tag ${FULL_IMAGE_NAME}:${IMAGE_TAG} \
        --tag ${FULL_IMAGE_NAME}:latest \
        .
fi

echo "==========================================="
echo "Multi-architecture build completed!"
echo "==========================================="
echo "Built platforms: ${PLATFORMS}"
echo "Images built:"
echo "  - ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
echo "  - ${FULL_IMAGE_NAME}:latest"
echo ""
echo "To run on different architectures:"
echo "  AMD64: docker run --platform linux/amd64 ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
echo "  ARM64: docker run --platform linux/arm64 ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Usage examples:"
echo "  ./build-multiarch.sh           # Local build for current platform"
echo "  ./build-multiarch.sh --push    # Build and push to registry (true multi-platform)"
echo ""
echo "To inspect the built manifest:"
echo "  docker buildx imagetools inspect ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Note: Only builds with --push will create true multi-platform images viewable in registry."
echo "Local builds will only build for your current platform ($(uname -m))."
echo "==========================================="
