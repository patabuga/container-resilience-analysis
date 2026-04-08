#!/bin/bash
# Capture Grafana Screenshots Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

# Configuration
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASS="${GRAFANA_PASS:-research2024}"

# Parse phase
PHASE=${1:-baseline}

case "${PHASE}" in
    baseline)
        EVIDENCE_DIR="${PROJECT_DIR}/evidence/baseline/screenshots"
        ;;
    contention)
        EVIDENCE_DIR="${PROJECT_DIR}/evidence/contention/screenshots"
        ;;
    throttling)
        EVIDENCE_DIR="${PROJECT_DIR}/evidence/throttling/screenshots"
        ;;
    spof)
        EVIDENCE_DIR="${PROJECT_DIR}/evidence/spof/screenshots"
        ;;
    *)
        echo "Usage: $0 {baseline|contention|throttling|spof}"
        exit 1
        ;;
esac

mkdir -p "${EVIDENCE_DIR}"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "=========================================="
echo "Capturing Grafana Screenshots"
echo "=========================================="
echo "Phase: ${PHASE}"
echo "Output: ${EVIDENCE_DIR}"
echo "Started: $(date)"
echo "=========================================="

# ============================================================
# Check if Grafana API is accessible
# ============================================================
echo ""
echo "[1/4] Checking Grafana API..."

if ! curl -s -u "${GRAFANA_USER}:${GRAFANA_PASS}" "${GRAFANA_URL}/api/health" > /dev/null; then
    echo "Error: Cannot connect to Grafana API"
    echo "Make sure Grafana is running and credentials are correct"
    exit 1
fi

echo "Grafana API is accessible."

# ============================================================
# Get Dashboard UIDs
# ============================================================
echo ""
echo "[2/4] Finding dashboards..."

DASHBOARDS=$(curl -s -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
    "${GRAFANA_URL}/api/search?query=cra" | jq -r '.[] | .uid + " " + .title')

if [ -z "${DASHBOARDS}" ]; then
    echo "Warning: No dashboards found. Creating default snapshots..."
    DASHBOARDS="cra-overview CRA Overview"
fi

echo "Found dashboards:"
echo "${DASHBOARDS}"

# ============================================================
# Capture Screenshots using Grafana Image Renderer
# ============================================================
echo ""
echo "[3/4] Capturing dashboard images..."

for DASHBOARD in ${DASHBOARDS}; do
    set -- ${DASHBOARD}
    UID=$1
    TITLE=$2
    
    echo "Capturing: ${TITLE} (${UID})"
    
    # Render dashboard panel
    curl -s -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
        "${GRAFANA_URL}/render/d/${UID}?width=1920&height=1080&timeout=60" \
        > "${EVIDENCE_DIR}/${TITLE// /_}-${TIMESTAMP}.png"
    
    if [ $? -eq 0 ]; then
        echo "  Saved: ${TITLE}-${TIMESTAMP}.png"
    else
        echo "  Failed: ${TITLE}"
    fi
done

# ============================================================
# Export Metrics as JSON
# ============================================================
echo ""
echo "[4/4] Exporting metrics data..."

PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"

# Paper A Metrics
curl -s "${PROMETHEUS_URL}/api/v1/query?query=container_cpu_usage_seconds_total" \
    > "${EVIDENCE_DIR}/paper-a-cpu-${TIMESTAMP}.json"

curl -s "${PROMETHEUS_URL}/api/v1/query?query=container_memory_usage_bytes" \
    > "${EVIDENCE_DIR}/paper-a-memory-${TIMESTAMP}.json"

curl -s "${PROMETHEUS_URL}/api/v1/query?query=container_cpu_cfs_throttled_seconds_total" \
    > "${EVIDENCE_DIR}/paper-a-throttling-${TIMESTAMP}.json"

# Paper B Metrics
curl -s "${PROMETHEUS_URL}/api/v1/query?query=nginx_upstream_down" \
    > "${EVIDENCE_DIR}/paper-b-upstream-${TIMESTAMP}.json"

curl -s "${PROMETHEUS_URL}/api/v1/query?query=nginx_http_request_duration_seconds" \
    > "${EVIDENCE_DIR}/paper-b-response-time-${TIMESTAMP}.json"

echo "Metrics exported."

echo ""
echo "=========================================="
echo "Screenshot Capture Complete!"
echo "=========================================="
echo "Location: ${EVIDENCE_DIR}"
echo "Files:"
ls -la "${EVIDENCE_DIR}"
echo "=========================================="

# ============================================================
# Generate View Command
# ============================================================
cat > "${EVIDENCE_DIR}/view-evidence.sh" <<EOF
#!/bin/bash
# View evidence for ${PHASE}
# Generated: $(date)

echo "Opening evidence directory..."
if command -v xdg-open &> /dev/null; then
    xdg-open "${EVIDENCE_DIR}"
elif command -v open &> /dev/null; then
    open "${EVIDENCE_DIR}"
else
    echo "Evidence location: ${EVIDENCE_DIR}"
    ls -la "${EVIDENCE_DIR}"
fi
EOF

chmod +x "${EVIDENCE_DIR}/view-evidence.sh"

echo ""
echo "To view evidence run: ${EVIDENCE_DIR}/view-evidence.sh"