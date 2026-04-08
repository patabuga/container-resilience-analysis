#!/bin/bash
# Deploy Container Stack Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

echo "=========================================="
echo "Deploying Container Resilience Stack"
echo "=========================================="
echo "Project: ${PROJECT_DIR}"
echo "Started: $(date)"
echo "=========================================="

cd "${PROJECT_DIR}"

# ============================================================
# STEP 1: Create Environment File
# ============================================================
echo ""
echo "[1/4] Creating environment file..."

cat > .env <<EOF
# WordPress Configuration
WP_DB_PASSWORD=research2024
MYSQL_ROOT_PASSWORD=rootpass2024

# Grafana Configuration
GRAFANA_ADMIN=admin
GRAFANA_PASSWORD=research2024

# Domain Configuration
DOMAIN=sbox.patabuga.co
EOF

echo "Environment file created."

# ============================================================
# STEP 2: Pull Docker Images
# ============================================================
echo ""
echo "[2/4] Pulling Docker images..."

docker compose -f docker/docker-compose.yml pull

echo "Images pulled."

# ============================================================
# STEP 3: Deploy Stack
# ============================================================
echo ""
echo "[3/4] Deploying services..."

docker compose -f docker/docker-compose.yml up -d

echo "Services deployed."

# ============================================================
# STEP 4: Wait for Health Checks
# ============================================================
echo ""
echo "[4/4] Waiting for services to be healthy..."

sleep 30

# Check status
docker compose -f docker/docker-compose.yml ps

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "Services:"
echo "  - Nginx:http://localhost"
echo "  - Grafana: http://localhost:3000"
echo "  - Prometheus: http://localhost:9090"
echo "  - cAdvisor: http://localhost:8080"
echo "  - Node Exporter: http://localhost:9100"
echo ""
echo "WordPress:"
echo "  - Setup: http://localhost/wp-admin/install.php"
echo "=========================================="