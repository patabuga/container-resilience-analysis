#!/bin/bash
# I/O Stress Test Script for Paper A - Resource Contention Analysis
# Usage: ./io-stress.sh <operations> <duration_seconds>

IO_OPS=${1:-1000}
DURATION=${2:-300}

echo "=========================================="
echo "Paper A: I/O Stress Test"
echo "=========================================="
echo "I/O Operations: ${IO_OPS} ops/sec"
echo "Duration: ${DURATION}s"
echo "Started: $(date)"
echo "=========================================="

# Run stress-ng with I/O load
docker run --rm \
    --name cra-io-stress \
    --volume /tmp/stress:/stress \
    polinux/stress-ng:latest \
    --iomix "${IO_OPS}" \
    --timeout "${DURATION}s" \
    --metrics-brief \
    --times

echo "=========================================="
echo "Completed: $(date)"
echo "=========================================="

# Log output location
# Captured by collect-evidence.sh