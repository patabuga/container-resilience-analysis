# Setup Guide

## Prerequisites

1. Azure VM with following specifications:
   - Size: Standard_B4ms (4 vCPU, 16 GB RAM)
   - OS: Ubuntu 22.04 LTS
   - Storage: 30 GB SSD

2. Domain configured in Cloudflare
   - `sbox.patabuga.co` pointing to VM IP
   - `*.sbox.patabuga.co` as CNAME

## Step 1: Provision Azure VM

```bash
# Start the VM if stopped
az vm start -g PES-CM-AZURE -n pes-sandbox

# Get public IP
az vm list-ip-addresses -g PES-CM-AZURE -n pes-sandbox
```

## Step 2: SSH Access

```bash
# Use the SSH key from password manager
ssh -i ~/.ssh/azure_sandbox_private sboxuser@<VM_IP>

# Or add to SSH config
cat >> ~/.ssh/config << EOF
Host pes-sandbox
    HostName <VM_IP>
    User sboxuser
    IdentityFile ~/.ssh/azure_sandbox_private
EOF

# Then simply
ssh pes-sandbox
```

## Step 3: Run Setup Script

```bash
# Clone repository
git clone https://github.com/patabuga/container-resilience-analysis.git
cd container-resilience-analysis

# Make scripts executable
chmod +x scripts/*.sh stress-ng/*.sh

# Run VM setup
./scripts/setup-vm.sh
```

## Step 4: Deploy Container Stack

```bash
# Deploy
./scripts/deploy-stack.sh

# Verify
docker compose ps
docker compose logs
```

## Step 5: Configure CloudflareDNS

### Manual Configuration (via Dashboard)

1. Login to Cloudflare Dashboard
2. Select domain `patabuga.co`
3. Go to DNS Records
4. Add records:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | sbox | <VM_IP> | Yes |
| CNAME | grafana | sbox.patabuga.co | Yes |
| CNAME | prometheus | sbox.patabuga.co | Yes |
| CNAME | wordpress | sbox.patabuga.co | Yes |

### Automated Configuration (via API)

```bash
# Get Cloudflare API token from password manager
CLOUDFLARE_API_TOKEN=$(pass show infrastructure/cloudflare/global-api-token)
CLOUDFLARE_ZONE_ID=$(pass show infrastructure/cloudflare/account-id)

# Create DNS records
curl -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{
        "type": "A",
        "name": "sbox",
        "content": "<VM_IP>",
        "proxied": true
    }'

curl -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{
        "type": "CNAME",
        "name": "grafana",
        "content": "sbox.patabuga.co",
        "proxied": true
    }'
```

## Step 6: Verify Services

```bash
# Check all services are running
docker compose ps

# Test Nginx
curl http://localhost/health

# Test Grafana
curl http://localhost:3000/api/health

# Test Prometheus
curl http://localhost:9090/-/healthy

# Test cAdvisor
curl http://localhost:8080/metrics
```

## Step 7: Initialize WordPress

1. Open browser to `http://sbox.patabuga.co`
2. Complete WordPress installation
3. Create test pages for JMeter

## Troubleshooting

### Docker Issues

```bash
# Check Docker status
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check logs
docker compose logs
```

### Network Issues

```bash
# Check port bindings
sudo netstat -tlnp | grep -E ':(80|3000|9090|8080|9100)'

# Check firewall
sudo ufw status
```

### Container Issues

```bash
#Restart specific container
docker compose restart nginx

# Rebuild containers
docker compose down
docker compose up -d
```

## Next Steps

1. Run baseline test: `./scripts/run-baseline.sh`
2. Run contention tests: `./stress-ng/run-contention.sh`
3. Collect evidence: `./scripts/collect-evidence.sh`