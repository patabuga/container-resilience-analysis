# Container Resilience Analysis

**Shared Testbed for Container Performance & Resilience Research**

Repository ini menyediakan infrastruktur pengujian terpadu untuk dua penelitian:

- **Paper A (resource-contention-analysis)**: Analisis resource contention dan CPU throttling pada Single-Host Docker deployment
- **Paper B (nginx-spof-mitigation)**: Evaluasi mitigasi SPOF pada Nginx Reverse Proxy dalam arsitektur kontainer

## Arsitektur Testbed

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Azure VM (pes-sandbox)                       │
│                    Standard_B4ms (4 vCPU, 16 GB RAM)                │
│                        Ubuntu22.04 LTS                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                     Docker Network                          │  │
│  │                                                              │  │
│  │  ┌─────────┐    ┌───────────┐    ┌───────────────────────┐ │  │
│  │  │  Nginx  │───▶│ WordPress │───▶│      MariaDB        │ │  │
│  │  │ Reverse │    │   (PHP)   │    │      (Database)       │ │  │
│  │  │  Proxy  │    └───────────┘    └───────────────────────┘ │  │
│  │  └────┬────┘                                                 │  │
│  │       │                                                      │  │
│  │  ┌────┴────────────────────────────────────────────────────┐│  │
│  │  │              Observability Stack                         ││  │
│  │  │  Prometheus │ cAdvisor │ Node Exporter │ Grafana      ││  │
│  │  └──────────────────────────────────────────────────────────┘│  │
│  │                                                              │  │
│  │  ┌────────────────────────────────────────────────────────────┐│  │
│  │  │              Load & Noise Tools                            ││  │
│  │  │  stress-ng (CPU/IO/Mem) │Apache JMeter                   ││  │
│  │  └────────────────────────────────────────────────────────────┘│  │
│  └─────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
        ┌─────────────────────┐ ┌─────────────────────┐
        │ Paper A (Dimas)      │ │ Paper B (Rizal)      │
        │Resource Contention   │ │ SPOF Mitigation      │
        │ Analysis             │ │ Evaluation           │
        └─────────────────────┘ └─────────────────────┘
```

## Komponen Utama

### 1. Target System (WordPress Stack)
| Komponen | Image | Port | Deskripsi |
|----------|-------|------|-----------|
| Nginx | `nginx:alpine` | 80, 443 | Reverse proxy dengan healthcheck |
| WordPress | `wordpress:php8.2-apache` | 9000 | CMS untuk pengujian beban |
| MariaDB | `mariadb:10.11` | 3306 | Database backend |

### 2. Observability Stack
| Komponen | Image | Port | Deskripsi |
|----------|-------|------|-----------|
| Prometheus | `prom/prometheus:v2.48.0` | 9090 | Time-series metrics |
| cAdvisor | `gcr.io/cadvisor/cadvisor:v0.47.0` | 8080 | Container metrics |
| Node Exporter | `prom/node-exporter:v1.7.0` | 9100 | Host metrics |
| Grafana| `grafana/grafana:10.2.0` | 3000 | Visualization dashboard |

### 3.Load & Noise Tools
| Komponen | Image | Deskripsi |
|----------|-------|-----------|
| stress-ng | `polinux/stress-ng` | CPU/IO/Memory stress generator |
| JMeter | `apache/jmeter:5.6` | HTTP load testing |

## Quick Start

### Prerequisites
- Azure VM dengan akses SSH
- Docker & Docker Compose terinstall
- Cloudflare DNS terkonfigurasi

### Deploy Stack

```bash
# Clone repository
git clone https://github.com/patabuga/container-resilience-analysis.git
cd container-resilience-analysis

# Deploy full stack
docker-compose -f docker/docker-compose.full.yml up -d

# Verify all services
docker-compose -f docker/docker-compose.full.yml ps
```

### Access Services

| Service | URL |
|---------|-----|
| Grafana | http://grafana.sbox.patabuga.co |
| Prometheus | http://prometheus.sbox.patabuga.co |
| WordPress | http://wordpress.sbox.patabuga.co |
| cAdvisor | http://sbox.patabuga.co:8080 |

## Skenario Pengujian

### Paper A: Resource Contention Analysis
| Fase | Deskripsi | Command |
|------|-----------|---------|
| Fase 1 | Baseline (10-1000 VU step-up) | `./scripts/run-baseline.sh` |
| Fase 2 | CPU Contention (50-80%) | `./scripts/run-contention.sh cpu` |
| Fase 3 | CPU Throttling Analysis | `./scripts/run-throttling.sh` |

### Paper B: SPOF Mitigation
| Skenario | Deskripsi | Command |
|----------|-----------|---------|
| S1 | Identifikasi SPOF | `./scripts/run-spof-tests.sh arch` |
| S2 | Timeout Analysis | `./scripts/run-spof-tests.sh timeout` |
| S3 | Healthcheck Test | `./scripts/run-spof-tests.sh healthcheck` |

## Evidence Collection

```bash
# Collect all evidence
./scripts/collect-evidence.sh

# Capture Grafana screenshots
./scripts/capture-screenshots.sh

# View collected evidence
./scripts/view-evidence.sh list
./scripts/view-evidence.sh paper-a fase-1
./scripts/view-evidence.sh paper-b scenario-2
```

## Repository Structure

```
container-resilience-analysis/
├── docker/                # Docker Compose configurations
├── nginx/                 # Nginx configs (max_fails, fail_timeout)
├── prometheus/           # Prometheus scrape configs & rules
├── grafana/                # Grafana dashboards
├── stress-ng/              # Stress test scripts
├── jmeter/                 # JMeter test plans
├── scripts/                # Automation scripts
├── docs/                   # Documentation
└── evidence/               # Collected evidence storage
```

## Related Repositories

| Repository | Deskripsi |
|------------|-----------|
| [resource-contention-analysis](https://github.com/patabuga/resource-contention-analysis) | Paper A - Dimas|
| [nginx-spof-mitigation](https://github.com/patabuga/nginx-spof-mitigation) | Paper B - Rizal |

## License

MIT License - See [LICENSE](LICENSE) for details.

## Authors

- **Paper A**: Dimas (Resource Contention Analysis)
- **Paper B**: Rizal (SPOF Mitigation Evaluation)
- **Testbed**: Patabuga Research Team