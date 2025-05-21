#!/usr/bin/env python3
import subprocess, sys, requests, time, numpy as np
import os
import argparse

def get_api_url():
    """Get the API Gateway URL from (in order):
    1. Command line argument
    2. Environment variable API_GATEWAY_URL
    3. Terraform output (fallback)
    """
    # Check command line argument first
    parser = argparse.ArgumentParser(description='Test API Gateway latency')
    parser.add_argument('--url', help='API Gateway URL to test')
    args = parser.parse_args()
    
    if args.url:
        return args.url.rstrip("/") + "/"
        
    # Check environment variable
    url = os.environ.get('API_GATEWAY_URL')
    if url:
        return url.rstrip("/") + "/"
        
    # Fall back to Terraform output
    try:
        raw = subprocess.check_output(
            ["terraform", "output", "-raw", "api_gateway_url"],
            stderr=subprocess.STDOUT
        )
        return raw.decode().strip().rstrip("/") + "/"
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print("❌ Error: No API Gateway URL provided and Terraform not available", file=sys.stderr)
        print("Please provide the URL via --url argument or API_GATEWAY_URL environment variable", file=sys.stderr)
        sys.exit(1)

def measure_latency(url, features, n_requests=100, warmup=50):
    """
    Sends `warmup` unmeasured requests, then `n_requests` timed requests
    over a single HTTP connection, and prints P10/P50/P90/P95.
    """
    session = requests.Session()   # reuse TCP/TLS connection
    payload = {"features": features}

    print(f"Warming up with {warmup} requests...")
    # warm-up (no timing)
    for _ in range(warmup):
        session.post(url, json=payload)

    print(f"\nMeasuring latency over {n_requests} requests...")
    # measured run
    latencies = []
    for i in range(n_requests):
        start = time.perf_counter()
        r = session.post(url, json=payload)
        if not r.ok:
            print(f"\nError on request {i}: {r.status_code} {r.text}")
            break
        latencies.append((time.perf_counter() - start) * 1000)
        if (i + 1) % 10 == 0:
            print(".", end="", flush=True)
    print("\n")

    for p in (10, 50, 90, 95, 99):
        print(f"P{p}: {np.percentile(latencies, p):.2f} ms")

if __name__ == "__main__":
    api = get_api_url()
    print("Testing API Gateway:", api)
    # example features—adjust to match your model
    test_features = [0.5, -1.2, 3.3, 0.0, 2.1, -0.7, 4.4, 5.5]
    measure_latency(api, test_features, n_requests=100)
