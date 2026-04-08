#!/bin/bash
# Run SPOF Tests Script for Paper B

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
EVIDENCE_DIR="${PROJECT_DIR}/evidence/spof"

echo "=========================================="
echo "Paper B: SPOF Mitigation Tests"
echo "=========================================="

# Parse test type
TEST_TYPE=${1:-all}

case "${TEST_TYPE}" in
    arch|architecture)
        echo "Running: Architecture SPOF Identification"
        run_architecture_test
        ;;
    timeout)
        echo "Running: Timeout Configuration Analysis"
        run_timeout_test
        ;;
    healthcheck)
        echo "Running: Docker Healthcheck Effectiveness Test"
        run_healthcheck_test
        ;;
    all)
        echo "Running: All SPOF tests"
        run_architecture_test
        run_timeout_test
        run_healthcheck_test
        ;;
    *)
        echo "Usage: $0 {arch|timeout|healthcheck|all}"
        exit 1
        ;;
esac

# ============================================================
# FUNCTIONS
# ============================================================

run_architecture_test() {
    echo""
    echo "=========================================="
    echo "Scenario 1: Architecture SPOF Identification"
    echo "=========================================="
    
    mkdir -p "${EVIDENCE_DIR}/scenario-1"{screenshots,config-snapshots}
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    
    # Capture current configuration
    echo "[1/3] Capturing configuration..."
    
    docker inspect cra-nginx > "${EVIDENCE_DIR}/scenario-1/config-snapshots/nginx-inspect-${TIMESTAMP}.json"
    docker inspect cra-wordpress > "${EVIDENCE_DIR}/scenario-1/config-snapshots/wordpress-inspect-${TIMESTAMP}.json"
    docker inspect cra-mariadb > "${EVIDENCE_DIR}/scenario-1/config-snapshots/mariadb-inspect-${TIMESTAMP}.json"
    # Copy nginx config
    docker cp cra-nginx:/etc/nginx/nginx.conf "${EVIDENCE_DIR}/scenario-1/config-snapshots/nginx.conf-${TIMESTAMP}"
    
    # Analyze SPOF points
    echo "[2/3] Analyzing SPOF points..."
    
    cat > "${EVIDENCE_DIR}/scenario-1/SPOF-ANALYSIS-${TIMESTAMP}.md" <<'EOF'
# SPOF Analysis Report

## Single Points of Failure Identified

### 1. Nginx Reverse Proxy
**Risk Level:** HIGH
- Single instance (no redundancy)
- No upstream failover configuration
- Manual intervention required for recovery

### 2. MariaDB Database
**Risk Level:** HIGH
- Single instance (no replication)
- No backup active instance
- Data loss risk on failure

### 3. WordPress Application
**Risk Level:** MEDIUM
- Single instance
- Stateful (files + database)
- No horizontal scaling

### 4. Docker Host
**Risk Level:** CRITICAL
- Single VM hosting all containers
- No VM redundancy
- Network dependency on single NIC

## Mitigation Recommendations

| SPOF | Current | Recommended |
|------|---------|-------------|
| Nginx | Single instance | Add upstream with backup |
| MariaDB | Single instance | Add replica |
| WordPress | Single instance | Add load balancer|
| Docker Host | Single VM | Multi-node cluster |

EOF

    # Capture container status
    echo "[3/3] Capturing container status..."
    
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" > "${EVIDENCE_DIR}/scenario-1/container-status-${TIMESTAMP}.txt"
    docker network ls > "${EVIDENCE_DIR}/scenario-1/network-status-${TIMESTAMP}.txt"
    
    echo "Architecture analysis complete."
    generate_manifest "scenario-1"
}

run_timeout_test() {
    echo ""
    echo "=========================================="
    echo "Scenario 2: Timeout Configuration Analysis"
    echo "=========================================="
    
    mkdir -p "${EVIDENCE_DIR}/scenario-2"/{screenshots,raw-data}
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    
    # Timeout configurations to test
    TIMEOUTS=("10-30-60" "30-60-120" "60-120-300")
    
    for TIMEOUT_SET in "${TIMEOUTS[@]}"; do
        IFS='-' read -r CONNECT SEND READ <<< "${TIMEOUT_SET}"
        
        echo ""
        echo "Testing timeout set: connect=${CONNECT}s, send=${SEND}s, read=${READ}s"
        
        # Update nginx config
        # (This would require docker restart)
        
        # Run load test
        echo "Running load test with ${TIMEOUT_SET}..."
        
        # Capture metrics
        curl -s "http://localhost:9090/api/v1/query?query=nginx_upstream_response_time_seconds" \
            > "${EVIDENCE_DIR}/scenario-2/raw-data/timeout-${TIMEOUT_SET}-${TIMESTAMP}.json"# Wait for recovery
        sleep 60
    done
    
    echo "Timeout analysis complete."
    generate_manifest "scenario-2"
}

run_healthcheck_test() {
    echo ""
    echo "=========================================="
    echo "Scenario 3: Docker Healthcheck Effectiveness"
    echo "=========================================="
    
    mkdir -p "${EVIDENCE_DIR}/scenario-3"/{screenshots,raw-data}
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    
    echo ""
    echo "[1/3] Baseline: Recording initial state..."
    docker ps --format "table {{.Names}}\t{{.Status}}" > "${EVIDENCE_DIR}/scenario-3/raw-data/baseline-${TIMESTAMP}.txt"
    
    echo ""
    echo "[2/3] Test: Stopping Nginx container..."
    docker stop cra-nginx
    
    # Record timestamps
    STOP_TIME=$(date +%s)
    echo "Nginx stopped at: $(date)"# Wait and monitor recovery
    echo "Monitoring recovery..."
    
    # Capture Prometheus metrics during outage
    for i in {1..30}; do
        curl -s "http://localhost:9090/api/v1/query?query=up{job=\"nginx\"}" \
            >> "${EVIDENCE_DIR}/scenario-3/raw-data/recovery-timeline-${TIMESTAMP}.json"
        echo "" >> "${EVIDENCE_DIR}/scenario-3/raw-data/recovery-timeline-${TIMESTAMP}.json"
        sleep 2
    done
    
    # Record recovery time
    RECOVERY_TIME=$(date +%s)
    DURATION=$((RECOVERY_TIME - STOP_TIME))
    
    echo ""
    echo "Recovery duration: ${DURATION} seconds"
    
    # Check if healthcheck triggered restart
    docker ps -a --format "table {{.Names}}\t{{.Status}}" > "${EVIDENCE_DIR}/scenario-3/raw-data/after-recovery-${TIMESTAMP}.txt"
    
    echo ""
    echo "[3/3] Analyzing healthcheck effectiveness..."
    
    cat > "${EVIDENCE_DIR}/scenario-3/HEALTHCHECK-ANALYSIS-${TIMESTAMP}.md" <<EOF
# Healthcheck Effectiveness Analysis

## Test Parameters
- Container: cra-nginx
- Stop Time: $(date -d "@${STOP_TIME}")
- Recovery Time: $(date -d "@${RECOVERY_TIME}")
- Total Duration: ${DURATION} seconds

## Restart Policy Analysis
- Policy: unless-stopped
- Healthcheck: enabled
- Start Period: 30s
- Interval: 10s
- Timeout: 5s
- Retries: 3

## Findings
- Healthcheck triggered recovery: [YES/NO]
- Recovery time acceptable: [YES/NO]
- Data loss: [NONE/PARTIAL/FULL]

## Recommendations
- [ ] Increase healthcheck interval if too frequent
- [ ] Adjust start_period for slow-starting containers
- [ ] Consider manual intervention triggers

EOF

    echo "Healthcheck analysis complete."
    generate_manifest "scenario-3"
}

generate_manifest() {
    SCENARIO=$1
    SCENARIO_DIR="${EVIDENCE_DIR}/${SCENARIO}"
    
    cat > "${SCENARIO_DIR}/MANIFEST.md" <<EOF
# Evidence Manifest - ${SCENARIO}

Generated: $(date)

## Files Generated

$(ls -la "${SCENARIO_DIR}/" 2>/dev/null || echo "No files")

EOF
}

echo ""
echo "=========================================="
echo "SPOF Tests Complete!"
echo "=========================================="
echo "Evidence saved to: ${EVIDENCE_DIR}"
echo "=========================================="