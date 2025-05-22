#!/usr/bin/env python3
import subprocess, sys, requests, time, numpy as np
import os
import argparse

# ── helper to discover the API Gateway invoke URL ──────────────────
def get_api_url():
    parser = argparse.ArgumentParser(description="Test API Gateway latency")
    parser.add_argument("--url", help="API Gateway URL to test")
    args, _ = parser.parse_known_args()

    if args.url:                                   # 1. CLI
        return args.url.rstrip("/") + "/"
    
    # 2. env var
    env_url = os.environ.get("API_GATEWAY_URL")
    if env_url:
        return env_url.rstrip("/") + "/"

    # 3. Terraform output
    raw = subprocess.check_output(
        ["terraform", "output", "-raw", "api_gateway_url"],
        stderr=subprocess.STDOUT,
    )
    return raw.decode().strip().rstrip("/") + "/"

# ── latency tester — now takes user_id only ────────────────────────
def measure_latency(url, user_id, n_requests=100, warmup=50):
    session = requests.Session()        # re‑use TCP connection
    payload = {"user_id": user_id}

    print(f"Warming up with {warmup} requests …")
    for _ in range(warmup):             # warm‑up (untimed)
        session.post(url, json=payload)

    latencies = []
    print(f"\nMeasuring latency over {n_requests} requests …")
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

# ── entry‑point ────────────────────────────────────────────────────
if __name__ == "__main__":
    api_url = get_api_url()
    print("Testing API Gateway:", api_url)

    test_user_id = 7            # one of the 50 rows you seeded
    measure_latency(api_url, test_user_id, n_requests=100)
