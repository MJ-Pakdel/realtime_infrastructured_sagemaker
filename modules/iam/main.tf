# IAM Roles and Policies

# Lambda execution IAM role
# Terraform AWS IAM Role resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "lambda" {
  name = "${var.name_prefix}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
  tags = merge(
    { Name = "${var.name_prefix}-lambda-role" },
    var.tags
  )
}

# Attach AWS Lambda basic execution policy (for CloudWatch Logs)
# Terraform AWS IAM Role Policy Attachment resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach AWS Lambda VPC access policy (for ENI creation in VPC)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Inline policy to allow Lambda to invoke SageMaker endpoint
# Terraform AWS IAM Role Policy resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy
data "aws_caller_identity" "current" {}
resource "aws_iam_role_policy" "lambda_sagemaker" {
  name   = "${var.name_prefix}-lambda-sagemaker"
  role   = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "sagemaker:InvokeEndpoint",
      Resource = "arn:aws:sagemaker:${var.region}:${data.aws_caller_identity.current.account_id}:endpoint/${var.name_prefix}-endpoint"
    }]
  })
}

# SageMaker execution IAM role (for SageMaker jobs and endpoints)
resource "aws_iam_role" "sagemaker" {
  name = "${var.name_prefix}-sagemaker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "sagemaker.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
  tags = merge(
    { Name = "${var.name_prefix}-sagemaker-role" },
    var.tags
  )
}

# Attach AmazonSageMakerFullAccess managed policy to SageMaker role
resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Add specific S3 access policy for SageMaker role
resource "aws_iam_role_policy" "sagemaker_s3_access" {
  name   = "${var.name_prefix}-sagemaker-s3-access"
  role   = aws_iam_role.sagemaker.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Resource = [
          "arn:aws:s3:::${var.name_prefix}-lambda-bucket",
          "arn:aws:s3:::${var.name_prefix}-lambda-bucket/*"
        ]
      }
    ]
  })
}
