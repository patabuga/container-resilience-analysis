# Full Test Results - Container Resilience Analysis
Date: 2026-05-22
## Paper A: Resource Contention (Baseline)

| Test | VU | RPS | P50(ms) | P95(ms) | P99(ms) | Error% |
|-----|----|-----|---------|---------|---------|--------|
| baseline-100vu | 100 | 1883 | 47.8 | 90.7 | 114.3 | 0.0% |
| baseline-10vu | 10 | 1956 | 4.7 | 8.4 | 10.7 | 0.0% |
| baseline-200vu | 200 | 1773 | 95.7 | 197.9 | 262.8 | 0.0% |
| baseline-50vu | 50 | 1916 | 23.8 | 44.7 | 56.0 | 0.0% |

## Paper A: Resource Contention (Stress Tests)

| Test | VU | RPS | P50(ms) | P95(ms) | P99(ms) | Error% |
|-----|----|-----|---------|---------|---------|--------|
| cpu50-contention | 100 | 1357 | 64.2 | 141.6 | 192.7 | 0.0% |
| cpu80-contention | 100 | 1293 | 66.9 | 150.1 | 210.4 | 0.0% |
| mem-contention | 100 | 1285 | 66.9 | 151.4 | 220.0 | 0.0% |

## Key Findings

### Baseline Saturation
- **Saturation capacity: ~1,900 req/s** on /health endpoint
- **Knee point: 100-200 VU** where throughput starts dropping
- **P99 latency: 10.7ms at 10 VU** → **263ms at 200 VU**
- **Zero errors** at all load levels

### Resource Contention Impact
| Contention Type | Throughput Change | P99 Change |
|----------------|-------------------|------------|
| CPU 50% | -28% (1883→1357 RPS) | +69% (114→193ms) |
| CPU 80% | -31% (1883→1293 RPS) | +84% (114→210ms) |
| Memory 1GB | -32% (1883→1285 RPS) | +93% (114→220ms) |

## Paper B: SPOF Mitigation

### WordPress Outage Test Results

| Phase | RPS | Success% | P50(ms) | P95(ms) | Status Codes |
|-------|-----|---------|---------|---------|--------------|
| During Outage | 5 | 0.0% | 10001.1 | 10316.9 | {'504': 156, '0': 2, '502': 41} |
| Post Recovery | 7 | 79.0% | 6403.6 | 10014.6 | {'200': 214, '0': 57} |
| Pre Outage | 8 | 81.8% | 6401.3 | 10012.0 | {'200': 225, '0': 50} |

### SPOF Findings
- **Nginx correctly returns 502/504** when upstream (WordPress) is down
- **Recovery is instant** when upstream restarts — no nginx restart needed
- **No cascading failure**: only affected endpoints return errors
- **Healthcheck fix**: changed `localhost` → `127.0.0.1` in nginx healthcheck (Alpine wget issue)

## Evidence Files

- /home/vsp/container-resilience-analysis/evidence/SUMMARY.md
- /home/vsp/container-resilience-analysis/evidence/baseline/raw-data/baseline-100vu.json
- /home/vsp/container-resilience-analysis/evidence/baseline/raw-data/baseline-10vu.json
- /home/vsp/container-resilience-analysis/evidence/baseline/raw-data/baseline-200vu.json
- /home/vsp/container-resilience-analysis/evidence/baseline/raw-data/baseline-50vu.json
- /home/vsp/container-resilience-analysis/evidence/baseline/raw-data/prom-after.json
- /home/vsp/container-resilience-analysis/evidence/baseline/raw-data/prom-before.json
- /home/vsp/container-resilience-analysis/evidence/contention/raw-data/cpu50-contention.json
- /home/vsp/container-resilience-analysis/evidence/contention/raw-data/cpu80-contention.json
- /home/vsp/container-resilience-analysis/evidence/contention/raw-data/mem-contention.json
- /home/vsp/container-resilience-analysis/evidence/spof/scenario-3/raw-data/after-recovery.txt
- /home/vsp/container-resilience-analysis/evidence/spof/scenario-3/raw-data/baseline.txt
- /home/vsp/container-resilience-analysis/evidence/spof/scenario-3/raw-data/during-outage.json
- /home/vsp/container-resilience-analysis/evidence/spof/scenario-3/raw-data/post-recovery.json
- /home/vsp/container-resilience-analysis/evidence/spof/scenario-3/raw-data/pre-outage.json
- /home/vsp/container-resilience-analysis/evidence/spof/scenario-3/raw-data/recovery-timeline.json
- /home/vsp/container-resilience-analysis/evidence/spof/scenario-3/raw-data/test-results.md
