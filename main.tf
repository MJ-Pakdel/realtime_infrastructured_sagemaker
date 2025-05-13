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
  source      = "./modules/iam"
  name_prefix = var.name_prefix
  region      = var.region
  tags        = var.tags
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
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.network.default_security_group_id
  lambda_role_arn   = module.iam.lambda_role_arn
  tags              = var.tags

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
