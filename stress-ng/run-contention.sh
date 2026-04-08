#!/bin/bash
# Orchestrator Script for Paper A - Phase 2 Contention Tests
# Runs multiple stress scenarios in sequence

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE_DIR="${SCRIPT_DIR}/../evidence/contention"

echo "=========================================="
echo "Paper A: Phase 2 - Resource Contention"
echo "=========================================="
echo "This script runs the following contention scenarios:"
echo "  1. CPU 50% + Load Test"
echo "  2. CPU 80% + Load Test"
echo "  3. I/O Contention + Load Test"
echo "=========================================="

# Create evidence directory
mkdir -p"${EVIDENCE_DIR}/raw-data"
mkdir -p "${EVIDENCE_DIR}/screenshots"

# Get timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# ============================================================
# SCENARIO 1: CPU 50% Contention
# ============================================================
echo ""
echo "[SCENARIO 1] CPU 50% Contention"
echo "Starting at: $(date)"

"${SCRIPT_DIR}/cpu-stress.sh" 50 300 2 &> "${EVIDENCE_DIR}/raw-data/cpu-50-stress-${TIMESTAMP}.log" &
STRESS_PID=$!

# Wait for stress to start
sleep 10

# Run JMeter load test
echo "Starting JMeter load test at 50% capacity..."
# ./run-jmeter.sh contention-50 &> "${EVIDENCE_DIR}/raw-data/jmeter-50-${TIMESTAMP}.log"

# Wait for completion
wait $STRESS_PID

echo "[SCENARIO 1] Completed at: $(date)"

# ============================================================
# SCENARIO 2: CPU 80% Contention
# ============================================================
echo ""
echo "[SCENARIO 2] CPU 80% Contention"
echo "Starting at: $(date)"

"${SCRIPT_DIR}/cpu-stress.sh" 80 300 2 &> "${EVIDENCE_DIR}/raw-data/cpu-80-stress-${TIMESTAMP}.log" &
STRESS_PID=$!

sleep 10

echo "Starting JMeter load test at 50% capacity..."
# ./run-jmeter.sh contention-80 &> "${EVIDENCE_DIR}/raw-data/jmeter-80-${TIMESTAMP}.log"

wait $STRESS_PID

echo "[SCENARIO 2] Completed at: $(date)"

# ============================================================
# SCENARIO 3: I/O Contention
# ============================================================
echo ""
echo "[SCENARIO 3] I/O Contention"
echo "Starting at: $(date)"

"${SCRIPT_DIR}/io-stress.sh" 1000 300 &> "${EVIDENCE_DIR}/raw-data/io-stress-${TIMESTAMP}.log" &
STRESS_PID=$!

sleep 10

echo "Starting JMeter load test..."
# ./run-jmeter.sh contention-io &> "${EVIDENCE_DIR}/raw-data/jmeter-io-${TIMESTAMP}.log"

wait $STRESS_PID

echo "[SCENARIO 3] Completed at: $(date)"

echo ""
echo "=========================================="
echo "All contention scenarios completed!"
echo "Evidence saved to: ${EVIDENCE_DIR}"
echo "=========================================="

# Generate manifest
echo "# Evidence Manifest - Phase 2 Contention" > "${EVIDENCE_DIR}/MANIFEST.md"
echo "" >> "${EVIDENCE_DIR}/MANIFEST.md"
echo "Generated: $(date)" >> "${EVIDENCE_DIR}/MANIFEST.md"
echo "" >> "${EVIDENCE_DIR}/MANIFEST.md"
echo "## Files" >> "${EVIDENCE_DIR}/MANIFEST.md"
ls -la "${EVIDENCE_DIR}/raw-data/" >> "${EVIDENCE_DIR}/MANIFEST.md"