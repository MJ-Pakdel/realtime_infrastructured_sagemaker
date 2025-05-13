# Example Terraform variable values
# (All values have reasonable defaults; update as needed for your environment.)

region        = "us-east-1"
name_prefix   = "mlops-demo"
# ECR image for Lambda will be provided later after building and pushing the image:
lambda_image_uri = "988182270763.dkr.ecr.us-east-1.amazonaws.com/mlops-demo-ecr:latest"
# S3 path to the model artifact:
model_s3_path = "s3://mlops-demo-lambda-bucket/model/model.tar.gz"
# SageMaker container image URI (must match the deployment region):
sagemaker_image_uri = "683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-scikit-learn:1.2-1-cpu-py3"
# Lambda configuration
# Old configuration:
# lambda_timeout = 60
# lambda_memory = 256
# New configuration for high throughput:
lambda_timeout = 5  # Reduced timeout to fail fast - most requests should complete in ~300ms
lambda_memory = 2048  # Increased memory for better CPU allocation and reduced cold starts

# SageMaker configuration
# Updated to supported instance type - more powerful for lower latency:
instance_type = "ml.c5.large"  # Better CPU performance than t2.medium
instance_count = 1
# New configuration for high throughput (commented out):
# instance_type = "ml.c5.xlarge"  # More powerful CPU instance
# instance_count = 2  # Multiple instances for better scaling
