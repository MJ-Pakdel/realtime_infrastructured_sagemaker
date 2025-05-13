# SageMaker Model, Endpoint Configuration, and Endpoint
# (Consumes model artifact from external S3 bucket)

# CloudWatch Log Group for SageMaker Endpoint
resource "aws_cloudwatch_log_group" "sagemaker" {
  name              = "/aws/sagemaker/Endpoints/${var.name_prefix}-endpoint"
  retention_in_days = 3
  tags = merge(
    { Name = "${var.name_prefix}-sagemaker-logs" },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# SageMaker Model
# Terraform AWS SageMaker Model resource:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_model
resource "aws_sagemaker_model" "model" {
  name               = "${var.name_prefix}-model"
  execution_role_arn = var.sagemaker_role_arn

  primary_container {
    image          = var.sagemaker_image_uri
    model_data_url = var.model_s3_path
    environment = {
    SAGEMAKER_PROGRAM          = "inference.py"
    SAGEMAKER_SUBMIT_DIRECTORY = "s3://mlops-demo-lambda-bucket/model/model.tar.gz"
    SAGEMAKER_REQUIREMENTS = "requirements.txt"
    }
  }

  # Removing VPC config to allow public internet access for package installation
  # vpc_config {
  #   subnets            = var.subnet_ids
  #   security_group_ids = [var.security_group_id]
  # }

  tags = merge(
    { Name = "${var.name_prefix}-model" },
    var.tags
  )
}

# SageMaker Endpoint Configuration
# Terraform AWS SageMaker Endpoint Configuration resource:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_endpoint_configuration
resource "aws_sagemaker_endpoint_configuration" "cfg" {
  name = "${var.name_prefix}-endpoint-config"

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.model.name
    instance_type          = var.instance_type
    initial_instance_count = var.instance_count
  }

  tags = merge(
    { Name = "${var.name_prefix}-endpoint-config" },
    var.tags
  )
}

# SageMaker Endpoint
# Terraform AWS SageMaker Endpoint resource:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_endpoint
resource "aws_sagemaker_endpoint" "endpoint" {
  name        = "${var.name_prefix}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.cfg.name

  tags = merge(
    { Name = "${var.name_prefix}-endpoint" },
    var.tags
  )
}
