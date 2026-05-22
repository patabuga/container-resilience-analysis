# Paper B: SPOF Mitigation Test Results
Generated: Fri May 22 05:02:07 PM WIB 2026

## Pre Outage
- Concurrency: 50
- Duration: 30s
- Total requests: 275
- Successful: 225
- Failed: 50 (18.18%)
- Throughput: 7.57 req/s
- P50: 6401.3ms, P95: 10012.0ms, P99: 10410.7ms
- Status codes: {'200': 225, '0': 50}
- Errors: {'timed out': 50}

## During Outage
- Concurrency: 50
- Duration: 30s
- Total requests: 199
- Successful: 0
- Failed: 199 (100.0%)
- Throughput: 4.73 req/s
- P50: 10001.1ms, P95: 10316.9ms, P99: 10461.8ms
- Status codes: {'504': 156, '0': 2, '502': 41}
- Errors: {'HTTP Error 504: Gateway Time-out': 156, 'timed out': 2, 'HTTP Error 502: Bad Gateway': 41}

## Post Recovery
- Concurrency: 50
- Duration: 30s
- Total requests: 271
- Successful: 214
- Failed: 57 (21.03%)
- Throughput: 7.45 req/s
- P50: 6403.6ms, P95: 10014.6ms, P99: 10471.5ms
- Status codes: {'200': 214, '0': 57}
- Errors: {'timed out': 57}

