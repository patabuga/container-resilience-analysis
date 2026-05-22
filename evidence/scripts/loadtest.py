#!/usr/bin/env python3
"""
Load Tester for Container Resilience Analysis (Paper B - Rizal)
Generates HTTP load and records response times, error rates, and throughput.
Outputs results in JSON format for analysis.
"""

import argparse
import json
import sys
import time
import threading
import statistics
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

class LoadTester:
    def __init__(self, target_url, concurrency, duration, ramp_up=10):
        self.target_url = target_url
        self.concurrency = concurrency
        self.duration = duration
        self.ramp_up = ramp_up
        self.results = []
        self.errors = []
        self.lock = threading.Lock()
        self.running = True
        self.start_time = None
        
    def worker(self, worker_id):
        """Single worker thread that makes requests."""
        while self.running:
            start = time.time()
            try:
                req = Request(self.target_url, method='GET')
                resp = urlopen(req, timeout=10)
                status = resp.status
                resp.read()  # Consume response
                resp.close()
                elapsed = time.time() - start
                
                with self.lock:
                    self.results.append({
                        'worker': worker_id,
                        'timestamp': start,
                        'elapsed': elapsed,
                        'status': status,
                        'success': True
                    })
            except HTTPError as e:
                elapsed = time.time() - start
                with self.lock:
                    self.results.append({
                        'worker': worker_id,
                        'timestamp': start,
                        'elapsed': elapsed,
                        'status': e.code,
                        'success': False,
                        'error': str(e)
                    })
            except Exception as e:
                elapsed = time.time() - start
                with self.lock:
                    self.results.append({
                        'worker': worker_id,
                        'timestamp': start,
                        'elapsed': elapsed,
                        'status': 0,
                        'success': False,
                        'error': str(e)
                    })
    
    def run(self):
        """Run the load test with ramp-up."""
        print(f"\n{'='*60}")
        print(f"LOAD TEST: {self.concurrency} workers, {self.duration}s duration")
        print(f"Target: {self.target_url}")
        print(f"Start: {datetime.now().isoformat()}")
        print(f"{'='*60}")
        
        self.start_time = time.time()
        threads = []
        
        # Create all threads but start them with ramp-up delay
        for i in range(self.concurrency):
            delay = (i / self.concurrency) * self.ramp_up
            t = threading.Thread(target=self.worker, args=(i,))
            threads.append(t)
            # Start with ramp-up delay
            if delay > 0:
                time.sleep(delay / self.concurrency)
            t.start()
        
        # Let test run for specified duration
        time.sleep(self.duration)
        self.running = False
        
        # Wait for all threads to finish
        for t in threads:
            t.join(timeout=5)
        
        end_time = time.time()
        actual_duration = end_time - self.start_time
        
        return self.analyze(actual_duration)
    
    def analyze(self, actual_duration):
        """Analyze test results."""
        total = len(self.results)
        if total == 0:
            return {
                'error': 'No requests completed',
                'total_requests': 0,
                'duration_sec': actual_duration
            }
        
        successes = [r for r in self.results if r['success']]
        failures = [r for r in self.results if not r['success']]
        elapsed_times = [r['elapsed'] for r in self.results if r['success']]
        all_elapsed = [r['elapsed'] for r in self.results]
        
        # Calculate percentiles
        def percentile(data, p):
            if not data:
                return 0
            sorted_data = sorted(data)
            k = (len(sorted_data) - 1) * p / 100
            f = int(k)
            c = f + 1
            if c >= len(sorted_data):
                return sorted_data[-1]
            return sorted_data[f] + (k - f) * (sorted_data[c] - sorted_data[f])
        
        result = {
            'test_info': {
                'target': self.target_url,
                'concurrency': self.concurrency,
                'planned_duration': self.duration,
                'ramp_up': self.ramp_up,
                'start_time': datetime.fromtimestamp(self.start_time).isoformat(),
                'end_time': datetime.fromtimestamp(self.start_time + actual_duration).isoformat(),
            },
            'summary': {
                'total_requests': total,
                'successful': len(successes),
                'failed': len(failures),
                'failure_rate_pct': round(len(failures) / total * 100, 2) if total > 0 else 0,
                'actual_duration_sec': round(actual_duration, 2),
                'throughput_rps': round(total / actual_duration, 2) if actual_duration > 0 else 0,
            },
            'latency_sec': {
                'min': round(min(all_elapsed), 4) if all_elapsed else 0,
                'max': round(max(all_elapsed), 4) if all_elapsed else 0,
                'avg': round(statistics.mean(all_elapsed), 4) if all_elapsed else 0,
                'median': round(statistics.median(all_elapsed), 4) if len(all_elapsed) > 1 else 0,
                'p50': round(percentile(all_elapsed, 50), 4),
                'p90': round(percentile(all_elapsed, 90), 4),
                'p95': round(percentile(all_elapsed, 95), 4),
                'p99': round(percentile(all_elapsed, 99), 4),
            },
            'status_codes': {}
        }
        
        # Count status codes
        for r in self.results:
            code = str(r['status'])
            result['status_codes'][code] = result['status_codes'].get(code, 0) + 1
        
        # Error breakdown
        error_counts = {}
        for r in failures:
            err = r.get('error', 'unknown')
            error_counts[err] = error_counts.get(err, 0) + 1
        if error_counts:
            result['error_breakdown'] = error_counts
        
        return result


def print_report(result):
    """Print formatted report."""
    print(f"\n{'='*60}")
    print(f"LOAD TEST RESULTS")
    print(f"{'='*60}")
    
    if 'error' in result:
        print(f"ERROR: {result['error']}")
        return
    
    s = result['summary']
    l = result['latency_sec']
    
    print(f"\n📊 SUMMARY")
    print(f"  Total requests:  {s['total_requests']}")
    print(f"  Successful:      {s['successful']}")
    print(f"  Failed:          {s['failed']} ({s['failure_rate_pct']}%)")
    print(f"  Duration:        {s['actual_duration_sec']}s")
    print(f"  Throughput:      {s['throughput_rps']} req/s")
    
    print(f"\n⏱  LATENCY")
    print(f"  Min:     {l['min']}s")
    print(f"  Max:     {l['max']}s")
    print(f"  Avg:     {l['avg']}s")
    print(f"  Median:  {l['median']}s")
    print(f"  P90:     {l['p90']}s")
    print(f"  P95:     {l['p95']}s")
    print(f"  P99:     {l['p99']}s")
    
    print(f"\n📟 STATUS CODES")
    for code, count in sorted(result['status_codes'].items()):
        print(f"  HTTP {code}: {count}")
    
    if 'error_breakdown' in result:
        print(f"\n❌ ERRORS")
        for err, count in result['error_breakdown'].items():
            print(f"  {err}: {count}")
    
    print(f"\n{'='*60}\n")


def main():
    parser = argparse.ArgumentParser(description='Load Tester for Container Resilience')
    parser.add_argument('--url', default='http://localhost/health', help='Target URL')
    parser.add_argument('--concurrency', type=int, default=10, help='Number of concurrent workers')
    parser.add_argument('--duration', type=int, default=60, help='Test duration in seconds')
    parser.add_argument('--ramp-up', type=int, default=10, help='Ramp-up time in seconds')
    parser.add_argument('--output', help='Output JSON file path')
    
    args = parser.parse_args()
    
    tester = LoadTester(
        target_url=args.url,
        concurrency=args.concurrency,
        duration=args.duration,
        ramp_up=args.ramp_up
    )
    
    result = tester.run()
    print_report(result)
    
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=2)
        print(f"Results saved to: {args.output}")
    
    # Return exit code based on failure rate
    if result.get('summary', {}).get('failure_rate_pct', 0) > 50:
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
