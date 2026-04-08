# Architecture Overview

## System Architecture

Container Resilience Analysis testbed consists ofthe following components:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Azure VM (pes-sandbox)                           │
│                    Standard_B4ms (4 vCPU, 16GB RAM)                     │
│                         Ubuntu 22.04 LTS                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                      Docker Network: frontend                      │ │
│  │                                                                    │ │
│  │    ┌──────────────┐                                               │ │
│  │    │    Nginx     │  Port: 80, 443                                │ │
│  │    │  Reverse     │  Config: max_fails=3, fail_timeout=30s       │ │
│  │    │   Proxy      │  Healthcheck: /health (10s interval)         │ │
│  │    └──────┬───────┘                                               │ │
│  │           │                                                        │ │
│  └───────────┼────────────────────────────────────────────────────────┘ │
│              │                                                          │
│  ┌───────────┼────────────────────────────────────────────────────────┐ │
│  │           ▼         Docker Network: backend                        │ │
│  │                                                                    │ │
│  │    ┌──────────────┐         ┌──────────────────┐                  │ │
│  │    │  WordPress   │────────▶│     MariaDB      │                 │ │
│  │    │   (PHP 8.2)  │  Port:9000│    (MySQL)      │                 │ │
│  │    │              │         │   Port: 3306     │                 │ │
│  │    └──────────────┘         └──────────────────┘                  │ │
│  │                                                                    │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                    Docker Network: monitoring                     │ │
│  │                                                                    │ │
│  │  ┌────────────┐ ┌────────────┐ ┌─────────────┐ ┌──────────────┐ │ │
│  │  │ Prometheus│ │  cAdvisor  │ │Node Exporter│ │   Grafana     │ │ │
│  │  │  Port:9090 │ │  Port:8080 │ │  Port:9100  │ │  Port: 3000   │ │ │
│  │  │  Interval:5s│ │  Metrics   │ │ Host Metrics│ │  Dashboards   │ │ │
│  │  └────────────┘ └────────────┘ └─────────────┘ └──────────────┘ │ │
│  │                                                                    │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                      Load & Noise Tools                            │ │
│  │                                                                    │ │
│  │  ┌────────────────────┐    ┌─────────────────────────────────┐   │ │
│  │  │    stress-ng       │    │      Apache JMeter             │   │ │
│  │  │  CPU/IO/Mem Stress │    │   HTTP Load Testing            │   │ │
│  │  │                    │    │   10-1000 Virtual Users         │   │ │
│  │  └────────────────────┘    └─────────────────────────────────┘   │ │
│  │                                                                    │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### Target System (WordPress Stack)

| Component | Image | CPU Limit | Memory Limit | Healthcheck |
|-----------|-------|-----------|--------------|-------------|
| Nginx | nginx:1.25-alpine | 0.5 | 256M | /health (10s) |
| WordPress | wordpress:6.4-php8.2 | 1.0 | 512M | /wp-admin/install.php (30s) |
| MariaDB | mariadb:10.11 | 1.0| 512M | healthcheck.sh (10s) |

### Observability Stack

| Component | Image | Port | Purpose |
|-----------|-------|------|---------|
| Prometheus | prom/prometheus:v2.48.0 | 9090 | Metrics collection (5s interval) |
| cAdvisor | gcr.io/cadvisor/cadvisor:v0.47.2 | 8080 | Container metrics |
| Node Exporter | prom/node-exporter:v1.7.0 | 9100 | Host metrics |
| Grafana | grafana/grafana:10.2.0 | 3000 | Visualization |

### Load Tools

| Tool | Image | Purpose |
|------|-------|---------|
| stress-ng | polinux/stress-ng:latest | CPU/IO/Memory contention |
| JMeter | apache/jmeter:5.6 | HTTP load testing |

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    External Access                         │
│                                                            │
│  sbox.patabuga.co ──────▶ Nginx (Port 80/443)             │
│  grafana.sbox.patabuga.co ─▶ Grafana (Port 3000)          │
│  prometheus.sbox.patabuga.co ─▶ Prometheus (Port 9090)    │
└─────────────────────────────────────────────────────────────┘
                            │
                    Cloudflare DNS
                    (Proxy Enabled)
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Docker Networks                         │
│                                                            │
│  frontend ───────▶ Nginx ◀───── WordPress                  │
│  backend ────────▶ WordPress ◀────▶ MariaDB               │
│  monitoring ─────▶ Prometheus ◀──── cAdvisor               │
│                                ◀──── Node Exporter          │
│                                ◀──── Grafana                │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Paper A: Resource Contention Analysis

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  stress-ng  │────▶│    Host     │────▶│ Prometheus  │
│   (Noise)   │     │   (CPU/IO)  │     │  (Metrics)   │
└─────────────┘     └─────────────┘     └──────┬──────┘┌─────────────┐     ┌─────────────┐     │      │
│   JMeter    │────▶│  WordPress  │────▶│      │
│   (Load)     │     │  (Target)   │     │      │
└─────────────┘     └─────────────┘     │      │
                                        │      │
                                        ▼      │
                                   ┌─────────────┐
                                   │   Grafana   │
                                   │ (Dashboard) │
                                   └─────────────┘
```

### Paper B: SPOF Mitigation Analysis

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   JMeter    │────▶│    Nginx    │────▶│  WordPress  │
│   (Load)    │     │  (SPOF)     │     │  (Backend)  │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                           │ Healthcheck/Failover
                           │
                           ▼
                    ┌─────────────┐
                    │   Docker    │
                    │ Restart Pol │
                    └─────────────┘
```

## Metrics Collected

### Paper A Metrics

| Metric | Source | Purpose |
|--------|--------|---------|
| container_cpu_usage_seconds_total | cAdvisor | CPU usage |
| container_memory_usage_bytes | cAdvisor | Memory usage |
| container_cpu_cfs_throttled_seconds_total | cAdvisor | Throttling time |
| nginx_http_request_duration_seconds | Nginx | Response time |
| nginx_http_requests_total | Nginx | Request count |

### Paper B Metrics

| Metric | Source | Purpose |
|--------|--------|---------|
| nginx_upstream_down | Nginx | Backend availability |
| nginx_connections_active | Nginx | Active connections |
| container_restart_count | Docker | Restart events |
| up | Prometheus | Service health |