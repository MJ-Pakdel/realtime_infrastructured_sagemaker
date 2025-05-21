# Root module variables

# AWS region for all resources
variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-west-2"
}

# Prefix to use for naming resources
variable "name_prefix" {
  description = "Prefix for resource names (e.g., project name)"
  type        = string
  default     = "mlops-demo"
}

# Tags to apply to all taggable resources
variable "tags" {
  description = "Map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

# Lambda configuration
variable "lambda_memory" {
  description = "Memory size (MB) for the Lambda function"
  type        = number
  default     = 128
  validation {
    condition     = var.lambda_memory >= 128 && var.lambda_memory <= 10240
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}
variable "lambda_timeout" {
  description = "Timeout (seconds) for the Lambda function"
  type        = number
  default     = 5
  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}
variable "lambda_image_uri" {
  description = "ECR image URI for the Lambda function container (provide after pushing image)"
  type        = string
  default     = ""
}

# VPC network configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (no NAT gateway, uses VPC endpoints)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/24"]
}

# SageMaker configuration
variable "instance_type" {
  description = "Instance type for SageMaker (e.g., ml.t2.medium)"
  type        = string
  default     = "ml.t2.medium"
}
variable "instance_count" {
  description = "Number of instances for SageMaker (e.g., for endpoint initial count)"
  type        = number
  default     = 1
  validation {
    condition     = var.instance_count >= 1
    error_message = "Instance count must be at least 1."
  }
}
variable "sagemaker_image_uri" {
  description = "Docker image URI for the SageMaker model (for inference). Uses AWS XGBoost by default."
  type        = string
  default     = "246618743249.dkr.ecr.us-west-2.amazonaws.com/sagemaker-xgboost:1.5-1"
}
variable "model_s3_path" {
  description = "S3 URI of your trained model artifact (model.tar.gz)"
  type        = string
  default     = ""
}

# AWS account ID (used for constructing ARNs)
variable "account_id" {
  description = "AWS account ID for resource ARNs"
  type        = string
  default     = "988182270763" # Replace with your actual account ID or use data source in main.tf
}


######################################################
#  Latency‑tester EC2 extras
######################################################

variable "ssh_key_name" {
  description = "Existing EC2 key‑pair name for SSH access (blank to skip SSH)"
  type        = string
  default     = ""         # fill in e.g. "my‑laptop‑key" if you use SSH
}

variable "my_ip_cidr" {
  description = "Your laptop's public IP in CIDR form, e.g. 198.51.100.42/32"
  type        = string
}


variable "feature_group_name" {
  description = "Name of the feature group for online store"
  type        = string
  default     = "real_time_features"
}