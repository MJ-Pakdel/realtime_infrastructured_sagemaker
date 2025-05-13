#!/bin/bash
set -e

# Use AWS profile "mj"
export AWS_PROFILE=mj
echo "🔐 Using AWS profile: $AWS_PROFILE"

# Get the bucket name, with a fallback
BUCKET_NAME=$(terraform output -raw artifact_bucket_name 2>/dev/null || echo "mlops-demo-lambda-bucket")
MODEL_S3_PATH="s3://$BUCKET_NAME/model/model.tar.gz"
echo "📄 Setting model_s3_path to: $MODEL_S3_PATH"

# Run destroy with the correct variable
echo "🗑️ Running terraform destroy..."
terraform destroy -var="model_s3_path=$MODEL_S3_PATH" -auto-approve

echo "✅ Infrastructure destroyed successfully" 