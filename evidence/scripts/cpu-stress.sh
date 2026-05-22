#!/bin/bash
# CPU Stress Test Script for Paper A - Resource Contention Analysis
# Usage: ./cpu-stress.sh <percentage> <duration_seconds> <cores>

PERCENTAGE=${1:-50}
DURATION=${2:-300}
CORES=${3:-2}

echo "=========================================="
echo "Paper A: CPU Stress Test"
echo "=========================================="
echo "Percentage: ${PERCENTAGE}%"
echo "Duration: ${DURATION}s"
echo "Cores: ${CORES}"
echo "Started: $(date)"
echo "=========================================="

# Run stress-ng with CPU load
docker run --rm \
    --name cra-cpu-stress \
    --cpus="${CORES}" \
    polinux/stress-ng:latest \
    --cpu "${CORES}" \
    --cpu-load "${PERCENTAGE}" \
    --timeout "${DURATION}s" \
    --metrics-brief \
    --times

echo "=========================================="
echo "Completed: $(date)"
echo "=========================================="#

# Log output location
# Captured by collect-evidence.sh