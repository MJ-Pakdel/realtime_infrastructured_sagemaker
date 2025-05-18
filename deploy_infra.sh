#!/bin/bash
set -e

# 1. Use AWS profile "mj"
export AWS_PROFILE=mj
echo "🔐 Using AWS profile: $AWS_PROFILE"

# 2. Get region directly from AWS CLI config
AWS_REGION=$(aws configure get region --profile mj || echo "us-east-1")
echo "🌎 Using AWS region: $AWS_REGION"

# 3. Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# 4. Create ECR & S3 first (fast resources)
echo "🚀 Creating ECR and S3 bucket..."
terraform apply -auto-approve \
  -target=module.ecr \
  -target=module.s3_artifact

# 5. Upload model to S3
echo "📤 Uploading model to S3..."
python sagemaker_handler/copy_to_s3.py

# 6. Tag and push Docker image to ECR
ECR_URI=$(terraform output -raw ecr_repository_url)
echo "🔗 ECR repo URI: $ECR_URI"

LOCAL_IMAGE="ml-inference-lambda:latest"
FULL_IMAGE="${ECR_URI}:latest"
echo "🏷 Tagging $LOCAL_IMAGE as $FULL_IMAGE..."
docker tag $LOCAL_IMAGE $FULL_IMAGE

ECR_DOMAIN="${ECR_URI%/*}"  # Extract the domain part of the ECR URI
echo "📦 ECR domain: $ECR_DOMAIN"

echo "🔄 Authenticating with ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_DOMAIN

echo "⬆️ Pushing image to ECR..."
docker push $FULL_IMAGE
echo "✅ Pushed $FULL_IMAGE"

# 7. Update lambda_image_uri in terraform.tfvars
echo "📝 Updating lambda_image_uri in terraform.tfvars..."
sed -i '' "s|lambda_image_uri = \".*\"|lambda_image_uri = \"$FULL_IMAGE\"|" terraform.tfvars
echo "✅ Updated terraform.tfvars with image URI: $FULL_IMAGE"

# 8. Deploy all remaining resources
echo "🚀 Deploying full infrastructure..."
terraform apply -auto-approve

echo "✅ Full infrastructure deployment complete!"
echo ""
echo "📋 Infrastructure outputs:"
terraform output

# 8. Extract important endpoints
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "API not yet deployed")
SAGEMAKER_ENDPOINT=$(terraform output -raw sagemaker_endpoint_name 2>/dev/null || echo "SageMaker endpoint not yet deployed")

echo ""
echo "🔗 API Gateway URL: $API_URL"
echo "🧠 SageMaker Endpoint: $SAGEMAKER_ENDPOINT"
echo ""
echo "You can now make inference requests to your API!" 