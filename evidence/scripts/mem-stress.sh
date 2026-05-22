#!/bin/bash
# Memory Stress Test Script for Paper A - Resource Contention Analysis
# Usage: ./mem-stress.sh <memory_mb> <duration_seconds>

MEMORY=${1:-1024}
DURATION=${2:-300}

echo "=========================================="
echo "Paper A: Memory Stress Test"
echo "=========================================="
echo "Memory: ${MEMORY}MB"
echo "Duration: ${DURATION}s"
echo "Started: $(date)"
echo "=========================================="

# Run stress-ng with memory load
docker run --rm \
    --name cra-mem-stress \
    --memory="${MEMORY}m" \
    polinux/stress-ng:latest \
    --vm 1 \
    --vm-bytes "${MEMORY}M" \
    --timeout "${DURATION}s" \
    --metrics-brief \
    --times

echo "=========================================="
echo "Completed: $(date)"
echo "=========================================="

# Log output location
# Captured by collect-evidence.sh