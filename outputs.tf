# Root module outputs

output "artifact_bucket_name" {
  description = "S3 bucket for model artifacts"
  value       = module.s3_artifact.bucket_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}
output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

output "aws_region" {
  description = "AWS region used for deployment"
  value       = var.region
}

output "api_gateway_url" {
  description = "Invoke URL for the API Gateway (HTTP API)"
  value       = module.apigateway.api_endpoint
}

output "sagemaker_endpoint_name" {
  description = "Name of the SageMaker Endpoint"
  value       = "${var.name_prefix}-endpoint"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}
output "security_group_id" {
  description = "ID of the default security group for internal access"
  value       = module.network.default_security_group_id
}

######################################################
#  EC2 latency‑tester outputs
######################################################

output "latency_tester_public_ip" {
  description = "Public IP address of the latency‑tester EC2 instance"
  value       = module.tester_ec2.public_ip
}

output "latency_tester_instance_id" {
  description = "Instance ID of the latency‑tester EC2"
  value       = module.tester_ec2.instance_id
}


output "feature_group_name" {
  value = module.feature_store.feature_group_name
}
output "feature_group_arn"  {
  value = module.feature_store.feature_group_arn
}

output "offline_prefix" {
  description = "S3 prefix for Feature Store offline data"
  value       = "feature-store/"   # keep the trailing slash
}