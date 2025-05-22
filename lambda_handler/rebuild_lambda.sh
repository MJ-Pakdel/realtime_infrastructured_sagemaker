#!/bin/bash
set -e  # Exit on any error

# Go to the parent directory where Terraform files are
cd "$(dirname "$0")/.."

# 1. Use AWS profile "mj"
export AWS_PROFILE=mj
echo "🔐 Using AWS profile: $AWS_PROFILE"

# 2. Get region from AWS CLI config
AWS_REGION=$(aws configure get region --profile mj || echo "us-east-1")
echo "🌎 Using AWS region: $AWS_REGION"

# # 3. Remove existing local Docker image
# LOCAL_IMAGE="ml-inference-lambda:latest"
# echo "🗑 Removing existing local Docker image..."
# docker rmi -f $LOCAL_IMAGE 2>/dev/null || true

# # 4. Build new Docker image
# echo "🏗 Building new Docker image..."
# cd lambda_handler
# docker build --platform linux/amd64 -t $LOCAL_IMAGE .
# cd ..

# # 5. Destroy ECR repository using Terraform
# echo "🗑 Destroying ECR repository..."
# terraform destroy -target=module.ecr -auto-approve

# # 6. Recreate ECR repository
# echo "🏗 Recreating ECR repository..."
# terraform apply -target=module.ecr -auto-approve

# Get ECR repository URL from Terraform
ECR_URI=$(terraform output -raw ecr_repository_url)
echo "🔗 ECR repo URI: $ECR_URI"

# # 8. Tag the new image
# echo "🏷 Tagging new image..."
# docker tag $LOCAL_IMAGE $FULL_IMAGE

# # 9. Login to ECR
# echo "🔄 Logging into ECR..."
# ECR_DOMAIN="${ECR_URI%/*}"  # Extract domain part of ECR URI
# aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_DOMAIN

# # 10. Push image to ECR
# echo "⬆️ Pushing image to ECR..."
# docker push $FULL_IMAGE

# Get the latest image digest from ECR
echo "🔍 Getting image digest..."
IMAGE_DIGEST=$(aws ecr describe-images --repository-name mlops-demo-ecr --image-ids imageTag=latest --query 'imageDetails[0].imageDigest' --output text)
FULL_IMAGE_WITH_DIGEST="${ECR_URI}@${IMAGE_DIGEST}"
echo "📝 Image digest: ${IMAGE_DIGEST}"

# First create Lambda resources with Terraform
echo "🏗 Creating Lambda resources..."
terraform apply -target=module.lambda -auto-approve

# Now update Lambda to use the exact image
echo "🔄 Updating Lambda function code..."
aws lambda update-function-code \
    --function-name mlops-demo-lambda \
    --image-uri $FULL_IMAGE_WITH_DIGEST \
    --publish

echo "⏳ Waiting for Lambda update to complete..."
aws lambda wait function-updated --function-name mlops-demo-lambda

# # Verify Lambda is using the new image
# echo "🔍 Verifying Lambda configuration..."
# LAMBDA_IMAGE=$(aws lambda get-function --function-name mlops-demo-lambda --query 'Code.ImageUri' --output text)
# if [ "$LAMBDA_IMAGE" = "$FULL_IMAGE_WITH_DIGEST" ]; then
#     echo "✅ Verification successful - Lambda is using the new image!"
# else
#     echo "❌ Verification failed!"
#     echo "Expected: $FULL_IMAGE_WITH_DIGEST"
#     echo "Found: $LAMBDA_IMAGE"
#     exit 1
# fi

# echo "✅ Lambda has been updated with the new image!"
# echo "🔗 Image URI with digest: $FULL_IMAGE_WITH_DIGEST" 