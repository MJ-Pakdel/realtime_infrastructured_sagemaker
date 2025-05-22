# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name_prefix}-lambda"
  retention_in_days = 3
  tags = merge(
    { Name = "${var.name_prefix}-lambda-logs" },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda function using container image
# Terraform AWS Lambda Function resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
resource "aws_lambda_function" "this" {
  function_name = "${var.name_prefix}-lambda"
  role          = var.lambda_role_arn
  package_type  = "Image"
  image_uri     = var.lambda_image_uri
  memory_size   = var.lambda_memory
  timeout       = var.lambda_timeout
  
  tracing_config {
    mode = "Active"
  }
  
  # # Deploy Lambda inside our VPC for access to internal services
  # vpc_config {
  #   subnet_ids         = var.subnet_ids
  #   security_group_ids = [var.security_group_id]
  # }
  
  # Add environment variables for SageMaker endpoint and Feature Store
  environment {
    variables = {
      SAGEMAKER_ENDPOINT = var.sagemaker_endpoint_name
      SM_FEATURE_GROUP  = var.feature_group_name
    }
  }
  
  tags = merge(
    { 
      Name = "${var.name_prefix}-lambda",
      Version = "1.0.1"
    },
    var.tags
  )
}

# Data source to get current region
data "aws_region" "current" {}
