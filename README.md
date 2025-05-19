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

## Quick Start

1. Configure AWS credentials:
```bash
export AWS_PROFILE=your_profile
```

2. Deploy infrastructure:
```bash
./deploy_infra.sh
```

3. Destroy infrastructure:
```bash
./destroy_infra.sh
```

## Project Structure

```
.
├── modules/
│   ├── network/      # VPC and security groups
│   ├── lambda/       # Lambda function configuration
│   └── sagemaker/    # SageMaker endpoint configuration
├── lambda_handler/   # Lambda function code
├── sagemaker_handler/# SageMaker inference code
├── deploy_infra.sh   # Deployment script
└── destroy_infra.sh  # Cleanup script
``` 