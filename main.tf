terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "mj"
}

# Root module - create AWS infrastructure using child modules
module "network" {
  source               = "./modules/network"
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  name_prefix          = var.name_prefix
  tags                 = var.tags
}

module "s3_artifact" {
  source      = "./modules/s3_artifact"
  name_prefix = var.name_prefix
  account_id  = var.account_id
  tags        = var.tags
}

module "iam" {
  source            = "./modules/iam"
  name_prefix       = var.name_prefix
  region            = var.region
  tags              = var.tags
  feature_group_arn = module.feature_store.feature_group_arn
}

module "ecr" {
  source      = "./modules/ecr"
  name_prefix = var.name_prefix
  tags        = var.tags
}

module "lambda" {
  source            = "./modules/lambda"
  name_prefix       = var.name_prefix
  lambda_memory     = var.lambda_memory
  lambda_timeout    = var.lambda_timeout
  lambda_image_uri  = var.lambda_image_uri
  # subnet_ids        = module.network.private_subnet_ids
  # security_group_id = module.network.default_security_group_id
  lambda_role_arn   = module.iam.lambda_role_arn
  tags              = var.tags

  # Environment variables
  sagemaker_endpoint_name = "${var.name_prefix}-endpoint"
  feature_group_name      = module.feature_store.feature_group_name

  # Ensure ECR repository is created before Lambda (which depends on an image being pushed)
  depends_on = [module.ecr]
}

module "apigateway" {
  source               = "./modules/apigateway"
  name_prefix          = var.name_prefix
  lambda_function_name = module.lambda.function_name
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_arn  = module.lambda.function_arn
  region              = var.region
  tags                 = var.tags
}

module "sagemaker" {
  source                  = "./modules/sagemaker"
  name_prefix             = var.name_prefix
  instance_type           = var.instance_type
  instance_count          = var.instance_count
  # VPC configuration removed - SageMaker endpoint now uses public internet
  # subnet_ids              = module.network.private_subnet_ids
  # security_group_id       = module.network.default_security_group_id
  sagemaker_role_arn      = module.iam.sagemaker_role_arn
  sagemaker_image_uri     = var.sagemaker_image_uri
  model_s3_path = var.model_s3_path
  tags                    = var.tags

  # Wait for all network resources (VPC endpoints) to be ready
  depends_on = [module.network]
}

# Allow EC2 to register with Systems Manager
resource "aws_iam_role" "latency_ssm" {
  name = "latency-tester-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "latency_ssm_core" {
  role       = aws_iam_role.latency_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "latency" {
  name = "latency-tester-ssm-profile"
  role = aws_iam_role.latency_ssm.name
}

module "tester_ec2" {
  source                 = "./modules/ec2"
  subnet_id              = module.network.public_subnet_ids[0]
  vpc_security_group_ids = [module.network.default_security_group_id]
  key_name               = ""  # no SSH key needed with SSM
  iam_instance_profile   = aws_iam_instance_profile.latency.name
}

module "feature_store" {
  source             = "./modules/feature_store"
  feature_group_name = "real_time_features"
  record_id_name     = "user_id"
  event_time_name    = "event_ts"
  role_arn           = module.iam.sagemaker_role_arn
  offline_s3_uri     = "s3://${module.s3_artifact.bucket_name}/feature-store/"
}