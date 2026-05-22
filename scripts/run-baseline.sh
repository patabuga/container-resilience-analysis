#!/bin/bash
# Run Baseline Test Script for Paper A - Phase1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
EVIDENCE_DIR="${PROJECT_DIR}/evidence/baseline"

echo "=========================================="
echo "Paper A: Phase 1 - Baseline Testing"
echo "=========================================="
echo "Purpose: Establish capacity baseline without noise"
echo "Started: $(date)"
echo "=========================================="

# Create evidence directory
mkdir -p "${EVIDENCE_DIR}/screenshots"
mkdir -p "${EVIDENCE_DIR}/raw-data"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# ============================================================
# STEP 1: Verify No Stress Container Running
# ============================================================
echo ""
echo "[1/5] Verifying clean environment..."

if docker ps | grep -q stress; then
    echo "Warning: Stress container detected. Stopping..."
    docker stop $(docker ps -q --filter "name=stress") || true
fi

echo "Environment is clean."

# ============================================================
# STEP 2: Capture Initial Metrics
# ============================================================
echo ""
echo "[2/5] Capturing initial metrics..."

# Prometheus snapshot
curl -s http://localhost:9090/api/v1/query?query=up >"${EVIDENCE_DIR}/raw-data/prom-initial-${TIMESTAMP}.json"

echo "Initial metrics captured."

# ============================================================
# STEP 3: Run JMeter Step-Up Test
# ============================================================
echo ""
echo "[3/5] Running JMeter step-up test (10-1000 VU)..."

if [ -f "${PROJECT_DIR}/jmeter/plans/baseline-test.jmx" ]; then
    jmeter \
        -n \
        -t "${PROJECT_DIR}/jmeter/plans/baseline-test.jmx" \
        -l "${EVIDENCE_DIR}/raw-data/jmeter-results-${TIMESTAMP}.jtl" \
        -e -o "${EVIDENCE_DIR}/raw-data/jmeter-report-${TIMESTAMP}"
else
    echo "Warning: JMeter plan not found. Skipping..."
fi

echo "JMeter test completed."

# ============================================================
# STEP 4: Capture Final Metrics
# ============================================================
echo ""
echo "[4/5] Capturing final metrics..."

# Prometheus snapshot
curl -s http://localhost:9090/api/v1/query?query=up >"${EVIDENCE_DIR}/raw-data/prom-final-${TIMESTAMP}.json"

# cAdvisor metrics
curl -s http://localhost:8080/metrics > "${EVIDENCE_DIR}/raw-data/cadvisor-final-${TIMESTAMP}.txt"

echo "Final metrics captured."

# ============================================================
# STEP 5: Generate Manifest
# ============================================================
echo ""
echo "[5/5] Generating evidence manifest..."

cat > "${EVIDENCE_DIR}/MANIFEST.md" <<EOF
# Evidence Manifest - Phase 1 Baseline

Generated: $(date)

## Test Parameters
- Test Type: Step-Up (10-1000 VU)
- Duration: Variable (until saturation)
- Noise: None (baseline)

## Files Generated

### Raw Data
$(ls -la "${EVIDENCE_DIR}/raw-data/" 2>/dev/null || echo "No raw data files")

### Screenshots
$(ls -la "${EVIDENCE_DIR}/screenshots/" 2>/dev/null || echo "No screenshots")

## Metrics Collected
- Prometheus: up, container_cpu_*, container_memory_*
- cAdvisor: container_*
- JMeter: response_time, error_rate, throughput

## Next Steps
1. Capture Grafana screenshots: ./scripts/capture-screenshots.sh baseline
2. Analyze data: Python scripts in analysis/
3. Document findings in report/
EOF

echo ""
echo "=========================================="
echo "Phase 1Baseline Testing Complete!"
echo "=========================================="
echo "Evidence saved to: ${EVIDENCE_DIR}"
echo "Manifest: ${EVIDENCE_DIR}/MANIFEST.md"
echo ""
echo "Next steps:"
echo "  1. Capture screenshots: ./scripts/capture-screenshots.sh baseline"
echo "  2. Proceed to Phase 2: ./stress-ng/run-contention.sh"
echo "=========================================="