#!/bin/bash

# MediaMTX and FFmpeg Startup Script
# This script starts MediaMTX server and publishes a video stream using FFmpeg

set -e  # Exit on error

echo "Starting MediaMTX server..."

# Start MediaMTX in the background
/usr/local/bin/mediamtx /app/mediamtx.yml &
MEDIAMTX_PID=$!

echo "MediaMTX started with PID: $MEDIAMTX_PID"

# Wait a moment for MediaMTX to fully start
sleep 3

echo "Starting FFmpeg stream publisher..."

# Check if video file exists
if [ ! -f "/app/videos/steel_factory.mp4" ]; then
    echo "Error: Video file not found at /app/videos/steel_factory.mp4"
    exit 1
fi

# Start FFmpeg to publish the video stream
# Loop the video indefinitely and publish to MediaMTX RTSP server
ffmpeg -re -stream_loop -1 -i /app/videos/steel_factory.mp4 \
    -c:v copy -c:a copy \
    -f rtsp \
    -rtsp_transport tcp \
    -avoid_negative_ts make_zero \
    -fflags +genpts \
    rtsp://localhost:8554/live &

FFMPEG_PID=$!
echo "FFmpeg started with PID: $FFMPEG_PID"

echo "=================================="
echo "MediaMTX Server is running!"
echo "--------------------------------"
echo "RTSP Stream: rtsp://localhost:8554/live"
echo "Web Interface: http://localhost:8888"
echo "HLS Stream: http://localhost:8888/live"
echo "WebRTC: http://localhost:8889"
echo "API: http://localhost:9997"
echo "Metrics: http://localhost:9998/metrics"
echo "=================================="

# Function to handle cleanup on script termination
cleanup() {
    echo "Shutting down services..."
    if kill -0 "$FFMPEG_PID" 2>/dev/null; then
        echo "Stopping FFmpeg (PID: $FFMPEG_PID)"
        kill "$FFMPEG_PID"
    fi
    if kill -0 "$MEDIAMTX_PID" 2>/dev/null; then
        echo "Stopping MediaMTX (PID: $MEDIAMTX_PID)"
        kill "$MEDIAMTX_PID"
    fi
    exit 0
}

# Set up signal handlers for graceful shutdown
trap cleanup SIGTERM SIGINT

# Wait for both processes to finish (or until interrupted)
wait
