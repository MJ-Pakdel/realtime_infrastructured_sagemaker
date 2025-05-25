# Real-time Inference Infrastructure

This repository contains Terraform infrastructure code for deploying a real-time machine learning inference pipeline using AWS SageMaker and Lambda.

## Architecture

![Solution Architecture](docs/Sagemaker%20-%20Serverless%20Predictor.jpeg)

## Request Flow

The real-time inference pipeline follows these steps:

1. **API Gateway Entry Point**: 
   - Client sends a prediction request to the API Gateway endpoint

2. **Lambda Processing**:
   - API Gateway forwards the request to AWS Lambda
   - Lambda function processes the incoming request
   - Features are retrieved from the online feature store
   - Additional features are derived on the fly as needed

3. **SageMaker Inference**:
   - Lambda sends the prepared feature set to the SageMaker endpoint
   - SageMaker model performs the prediction
   - Prediction results are returned to Lambda

4. **Response Handling**:
   - Lambda logs application metrics including:
     - Original request details
     - Prediction outcomes
     - Processing metadata
   - Results are formatted and returned to the client via API Gateway

This architecture ensures fast, scalable, and reliable real-time predictions while maintaining comprehensive logging for monitoring and debugging purposes.



