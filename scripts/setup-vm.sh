#!/bin/bash
# Setup VM Script for Container Resilience Analysis
# Run on Azure VM pes-sandbox

set -e

echo "=========================================="
echo "Container Resilience Analysis - VM Setup"
echo "=========================================="
echo "Target: Azure VM pes-sandbox (Ubuntu 22.04)"
echo "Started: $(date)"
echo "=========================================="

# ============================================================
# STEP 1: System Updates
# ============================================================
echo ""
echo "[1/8] Updating system packages..."

sudo apt-get update
sudo apt-get upgrade -y

# ============================================================
# STEP 2: Install Docker
# ============================================================
echo ""
echo "[2/8] Installing Docker..."

# Remove old versions
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

# Install dependencies
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker

echo "Docker version:"
docker --version

# ============================================================
# STEP 3: Install stress-ng
# ============================================================
echo ""
echo "[3/8] Installing stress-ng..."

sudo apt-get install -y stress-ng

# ============================================================
# STEP 4: Install JMeter
# ============================================================
echo ""
echo "[4/8] Installing Apache JMeter..."

# Install Java
sudo apt-get install -y openjdk-17-jdk

# Download JMeter
JMETER_VERSION="5.6"
JMETER_MIRROR="https://downloads.apache.org//jmeter/binaries"

wget"${JMETER_MIRROR}/apache-jmeter-${JMETER_VERSION}.tgz"
tar -xzf "apache-jmeter-${JMETER_VERSION}.tgz"
sudo mv"apache-jmeter-${JMETER_VERSION}" /opt/jmeter
rm "apache-jmeter-${JMETER_VERSION}.tgz"

# Add to PATH
echo 'export PATH=$PATH:/opt/jmeter/bin' >> ~/.bashrc

echo "JMeter installed at /opt/jmeter"

# ============================================================
# STEP 5: Install Prometheus Node Exporter (already in Docker)
# ============================================================
echo ""
echo "[5/8] Skipping Node Exporter (will run in Docker)"

# ============================================================
# STEP 6: Clone Repository
# ============================================================
echo ""
echo "[6/8] Cloning repository..."

cd /home/sboxuser
git clone https://github.com/patabuga/container-resilience-analysis.git
cd container-resilience-analysis

# Make scripts executable
chmod +x stress-ng/*.sh
chmod +x scripts/*.sh

# ============================================================
# STEP 7: Configure Firewall
# ============================================================
echo ""
echo "[7/8] Configuring firewall..."

sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 8080/tcp  # cAdvisor
sudo ufw allow 9100/tcp  # Node Exporter

sudo ufw --force enable

# ============================================================
# STEP 8: Initialize Evidence Directories
# ============================================================
echo ""
echo "[8/8] Initializing evidence directories..."

mkdir -p evidence/{baseline,contention,throttling,spof}/{screenshots,raw-data}

echo ""
echo "=========================================="
echo "VM Setup Complete!"
echo "=========================================="
echo "Next steps:"
echo "  1. Logout and login again (for Docker group)"
echo "  2. Run: ./scripts/deploy-stack.sh"
echo "  3. Verify: docker compose ps"
echo "=========================================="