# Real-time Inference Infrastructure

This repository contains Terraform infrastructure code for deploying a real-time machine learning inference pipeline using AWS SageMaker and Lambda.

## Architecture

![Solution Architecture](docs/Sagemaker%20-%20Serverless%20Predictor.jpeg)

## Components

- **AWS SageMaker**: Hosts the ML model for real-time inference
- **AWS Lambda**: Handles API requests and forwards them to SageMaker
- **API Gateway**: Provides REST API endpoint for client applications
- **VPC**: Secure network infrastructure for Lambda and SageMaker
- **Security Groups**: Controls network access between components

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed
- Python 3.8+ for Lambda and SageMaker handlers



## Latency Testing Instructions


### Step-by-Step Guide

#### 1. Local Machine Setup

Install AWS Session Manager Plugin:
```bash
brew install session-manager-plugin
```

Set your AWS Profile:
```bash
export AWS_PROFILE=mj  # or your profile name
```

Get your API Gateway URL (save for later):
```bash
terraform output -raw api_gateway_url
```

#### 2. Connect to Test EC2 Instance

Start an SSM session:
```bash
aws ssm start-session --target $(terraform output -raw latency_tester_instance_id)
```

#### 3. On EC2 Instance

Navigate to home directory:
```bash
cd ~
```

Create the test script:
```bash
cat > test_gateway.py <<'EOF'
#!/usr/bin/env python3
import subprocess, sys, requests, time, numpy as np
import os
import argparse

def get_api_url():
    parser = argparse.ArgumentParser(description='Test API Gateway latency')
    parser.add_argument('--url', help='API Gateway URL to test')
    args = parser.parse_args()
    
    if args.url:
        return args.url.rstrip("/") + "/"
        
    url = os.environ.get('API_GATEWAY_URL')
    if url:
        return url.rstrip("/") + "/"
        
    try:
        raw = subprocess.check_output(
            ["terraform", "output", "-raw", "api_gateway_url"],
            stderr=subprocess.STDOUT
        )
        return raw.decode().strip().rstrip("/") + "/"
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print("❌ Error: No API Gateway URL provided", file=sys.stderr)
        print("Please provide the URL via --url argument or API_GATEWAY_URL environment variable", file=sys.stderr)
        sys.exit(1)

def measure_latency(url, features, n_requests=100, warmup=50):
    session = requests.Session()
    payload = {"features": features}

    print(f"Warming up with {warmup} requests...")
    for _ in range(warmup):
        session.post(url, json=payload)

    print(f"\nMeasuring latency over {n_requests} requests...")
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
    test_features = [0.5, -1.2, 3.3, 0.0, 2.1, -0.7, 4.4, 5.5]
    measure_latency(api, test_features, n_requests=100)
EOF
```

Make the script executable:
```bash
chmod +x test_gateway.py
```

Install Python dependencies:
```bash
pip3 uninstall -y urllib3 requests
pip3 install 'urllib3<2.0' requests numpy
```

Run the latency test:
```bash
python3 test_gateway.py --url YOUR_API_GATEWAY_URL
```
