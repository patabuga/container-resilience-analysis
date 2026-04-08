#!/bin/bash
# Collect All Evidence Script
# Aggregates evidence from all test phases

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
EVIDENCE_ROOT="${PROJECT_DIR}/evidence"

echo "=========================================="
echo "Collecting All Evidence"
echo "=========================================="
echo "Project: ${PROJECT_DIR}"
echo "Started: $(date)"
echo "=========================================="

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
COLLECTION_DIR="${EVIDENCE_ROOT}/collection-${TIMESTAMP}"

mkdir -p "${COLLECTION_DIR}"

# ============================================================
# STEP 1: Collect Paper A Evidence
# ============================================================
echo ""
echo "[1/4] Collecting Paper A evidence..."

if [ -d "${EVIDENCE_ROOT}/baseline" ]; then
    echo "  Copying baseline evidence..."
    cp -r "${EVIDENCE_ROOT}/baseline" "${COLLECTION_DIR}/paper-a-baseline"
fi

if [ -d "${EVIDENCE_ROOT}/contention" ]; then
    echo "  Copying contention evidence..."
    cp -r "${EVIDENCE_ROOT}/contention" "${COLLECTION_DIR}/paper-a-contention"
fi

if [ -d "${EVIDENCE_ROOT}/throttling" ]; then
    echo "  Copying throttling evidence..."
    cp -r "${EVIDENCE_ROOT}/throttling" "${COLLECTION_DIR}/paper-a-throttling"
fi

# ============================================================
# STEP 2: Collect Paper B Evidence
# ============================================================
echo ""
echo "[2/4] Collecting Paper B evidence..."

if [ -d "${EVIDENCE_ROOT}/spof" ]; then
    echo "  Copying SPOF evidence..."
    cp -r "${EVIDENCE_ROOT}/spof" "${COLLECTION_DIR}/paper-b-spof"
fi

# ============================================================
# STEP 3: Export Prometheus Data
# ============================================================
echo ""
echo "[3/4] Exporting Prometheus time-series data..."

PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"

# Export all relevant metrics
METRICS=(
    "container_cpu_usage_seconds_total"
    "container_memory_usage_bytes"
    "container_cpu_cfs_throttled_seconds_total"
    "nginx_http_requests_total"
    "nginx_http_request_duration_seconds"
    "nginx_upstream_down"
    "up"
)

for METRIC in "${METRICS[@]}"; do
    echo "  Exporting: ${METRIC}"
    curl -s "${PROMETHEUS_URL}/api/v1/query?query=${METRIC}" \
        > "${COLLECTION_DIR}/${METRIC}-${TIMESTAMP}.json"
done

# ============================================================
# STEP 4: Generate Summary Report
# ============================================================
echo ""
echo "[4/4] Generating summary report..."

cat > "${COLLECTION_DIR}/EVIDENCE-SUMMARY-${TIMESTAMP}.md" <<EOF
# Evidence Collection Summary

**Generated:** $(date)
**Collection ID:** ${TIMESTAMP}

## Directory Structure

\`\`\`
${COLLECTION_DIR}/
├── paper-a-baseline/
│   ├── screenshots/
│   ├── raw-data/
│   └── MANIFEST.md
├── paper-a-contention/
├── paper-a-throttling/
├── paper-b-spof/
├── container_cpu_usage_seconds_total-*.json
├── container_memory_usage_bytes-*.json
├── container_cpu_cfs_throttled_seconds_total-*.json
├── nginx_http_requests_total-*.json
├── nginx_http_request_duration_seconds-*.json
├── nginx_upstream_down-*.json
└── up-*.json
\`\`\`

## Evidence Inventory

### Paper A: Resource Contention Analysis
| Phase | Status | Files |
|-------|--------|-------|
| Baseline | $( [ -d "${COLLECTION_DIR}/paper-a-baseline" ] && echo "✓ Complete" || echo "✗ Missing" ) | $( find "${COLLECTION_DIR}/paper-a-baseline" -type f 2>/dev/null | wc -l ) |
| Contention | $( [ -d "${COLLECTION_DIR}/paper-a-contention" ] && echo "✓ Complete" || echo "✗ Missing" ) | $( find "${COLLECTION_DIR}/paper-a-contention" -type f 2>/dev/null | wc -l ) |
| Throttling | $( [ -d "${COLLECTION_DIR}/paper-a-throttling" ] && echo "✓ Complete" || echo "✗ Missing" ) | $( find "${COLLECTION_DIR}/paper-a-throttling" -type f 2>/dev/null | wc -l ) |

### Paper B: SPOF Mitigation Analysis
| Scenario | Status | Files |
|----------|--------|-------|
| Architecture | $( [ -d "${COLLECTION_DIR}/paper-b-spof/scenario-1" ] && echo "✓ Complete" || echo "✗ Missing" ) | $( find "${COLLECTION_DIR}/paper-b-spof/scenario-1" -type f 2>/dev/null | wc -l ) |
| Timeout | $( [ -d "${COLLECTION_DIR}/paper-b-spof/scenario-2" ] && echo "✓ Complete" || echo "✗ Missing" ) | $( find "${COLLECTION_DIR}/paper-b-spof/scenario-2" -type f 2>/dev/null | wc -l ) |
| Healthcheck | $( [ -d "${COLLECTION_DIR}/paper-b-spof/scenario-3" ] && echo "✓ Complete" || echo "✗ Missing" ) | $( find "${COLLECTION_DIR}/paper-b-spof/scenario-3" -type f 2>/dev/null | wc -l ) |

## Prometheus Metrics Exported

EOF# Add metrics list
for METRIC in "${METRICS[@]}"; do
    echo "- ${METRIC}" >> "${COLLECTION_DIR}/EVIDENCE-SUMMARY-${TIMESTAMP}.md"
done

cat >> "${COLLECTION_DIR}/EVIDENCE-SUMMARY-${TIMESTAMP}.md" <<EOF

## Next Steps

1. **Paper A Analysis:** Use Python scripts in \`resource-contention-analysis/analysis/\`
2. **Paper B Analysis:** Use Python scripts in \`nginx-spof-mitigation/analysis/\`
3. **Generate Charts:** Run \`./scripts/generate-charts.sh\`
4. **Report Writing:** Use templates in \`report/\`

## Timestamps

- Collection Started: $(date)
- Collection Completed: $(date)

EOF

echo ""
echo "=========================================="
echo "Evidence Collection Complete!"
echo "=========================================="
echo "Collection Directory: ${COLLECTION_DIR}"
echo "Summary Report: ${COLLECTION_DIR}/EVIDENCE-SUMMARY-${TIMESTAMP}.md"
echo ""
echo "Total files collected: $(find "${COLLECTION_DIR}" -type f | wc -l)"
echo "Total size: $(du -sh "${COLLECTION_DIR}" | cut -f1)"
echo "=========================================="

# Create archive
echo ""
echo "Creating archive..."
tar -czf "${EVIDENCE_ROOT}/evidence-${TIMESTAMP}.tar.gz" -C "${EVIDENCE_ROOT}" "collection-${TIMESTAMP}"
echo "Archive created: ${EVIDENCE_ROOT}/evidence-${TIMESTAMP}.tar.gz"