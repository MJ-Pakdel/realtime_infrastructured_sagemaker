  # Create VPC
  # Terraform AWS VPC resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
  resource "aws_vpc" "this" {
    cidr_block           = var.vpc_cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = merge(
      { Name = "${var.name_prefix}-vpc" },
      var.tags
    )
  }

  # Create private subnets
  # Terraform AWS Subnet resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
  data "aws_availability_zones" "available" {
    state = "available"
  }
  resource "aws_subnet" "private" {
    count                   = length(var.private_subnet_cidrs)
    vpc_id                  = aws_vpc.this.id
    cidr_block              = var.private_subnet_cidrs[count.index]
    availability_zone       = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = false
    tags = merge(
      { Name = "${var.name_prefix}-subnet-${count.index + 1}" },
      var.tags
    )
  }

  # Create a dedicated security group for VPC endpoints
  resource "aws_security_group" "vpc_endpoint" {
    name        = "${var.name_prefix}-vpc-endpoint-sg"
    description = "Security group for VPC endpoints"
    vpc_id      = aws_vpc.this.id
    tags = merge(
      { Name = "${var.name_prefix}-vpc-endpoint-sg" },
      var.tags
    )
  }

  # Allow HTTPS inbound from the VPC CIDR
  resource "aws_security_group_rule" "vpc_endpoint_https_inbound" {
    type              = "ingress"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = [var.vpc_cidr]
    security_group_id = aws_security_group.vpc_endpoint.id
    description       = "Allow HTTPS inbound from VPC"
  }

  # Allow all outbound traffic
  resource "aws_security_group_rule" "vpc_endpoint_all_outbound" {
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.vpc_endpoint.id
    description       = "Allow all outbound traffic"
  }

  # Create a default security group for internal resources
  resource "aws_security_group" "default" {
    name        = "${var.name_prefix}-default-sg"
    description = "Default SG for internal access"
    vpc_id      = aws_vpc.this.id
    tags = merge(
      { Name = "${var.name_prefix}-sg" },
      var.tags
    )
  }

  # Allow all traffic within the security group
  resource "aws_security_group_rule" "internal_allow_all" {
    type              = "ingress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    self              = true
    security_group_id = aws_security_group.default.id
  }

  # Allow all outbound traffic
  resource "aws_security_group_rule" "allow_all_outbound" {
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.default.id
  }

  # S3 endpoint (Gateway type)
  resource "aws_vpc_endpoint" "s3" {
    vpc_id            = aws_vpc.this.id
    service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
    vpc_endpoint_type = "Gateway"
    route_table_ids   = [aws_vpc.this.default_route_table_id]
    tags = merge(
      { Name = "${var.name_prefix}-s3-endpoint" },
      var.tags
    )
  }

  # ECR API endpoint
  resource "aws_vpc_endpoint" "ecr_api" {
    vpc_id              = aws_vpc.this.id
    service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = aws_subnet.private[*].id
    security_group_ids  = [aws_security_group.vpc_endpoint.id]
    private_dns_enabled = true
    tags = merge(
      { Name = "${var.name_prefix}-ecr-api-endpoint" },
      var.tags
    )
  }

  # ECR DKR endpoint
  resource "aws_vpc_endpoint" "ecr_dkr" {
    vpc_id              = aws_vpc.this.id
    service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = aws_subnet.private[*].id
    security_group_ids  = [aws_security_group.vpc_endpoint.id]
    private_dns_enabled = true
    tags = merge(
      { Name = "${var.name_prefix}-ecr-dkr-endpoint" },
      var.tags
    )
  }

  # SageMaker API endpoint
  resource "aws_vpc_endpoint" "sagemaker_api" {
    vpc_id              = aws_vpc.this.id
    service_name        = "com.amazonaws.${data.aws_region.current.name}.sagemaker.api"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = aws_subnet.private[*].id
    security_group_ids  = [aws_security_group.vpc_endpoint.id]
    private_dns_enabled = true
    tags = merge(
      { Name = "${var.name_prefix}-sagemaker-api-endpoint" },
      var.tags
    )
  }

  # SageMaker Runtime endpoint
  resource "aws_vpc_endpoint" "sagemaker_runtime" {
    vpc_id              = aws_vpc.this.id
    service_name        = "com.amazonaws.${data.aws_region.current.name}.sagemaker.runtime"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = aws_subnet.private[*].id
    security_group_ids  = [aws_security_group.vpc_endpoint.id]
    private_dns_enabled = true
    tags = merge(
      { Name = "${var.name_prefix}-sagemaker-runtime-endpoint" },
      var.tags
    )
  }

  # CloudWatch Logs endpoint
  resource "aws_vpc_endpoint" "cloudwatch_logs" {
    vpc_id              = aws_vpc.this.id
    service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = aws_subnet.private[*].id
    security_group_ids  = [aws_security_group.vpc_endpoint.id]
    private_dns_enabled = true
    tags = merge(
      { Name = "${var.name_prefix}-logs-endpoint" },
      var.tags
    )
  }

  # CloudWatch Metrics endpoint
  resource "aws_vpc_endpoint" "cloudwatch_metrics" {
    vpc_id              = aws_vpc.this.id
    service_name        = "com.amazonaws.${data.aws_region.current.name}.monitoring"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = aws_subnet.private[*].id
    security_group_ids  = [aws_security_group.vpc_endpoint.id]
    private_dns_enabled = true
    tags = merge(
      { Name = "${var.name_prefix}-metrics-endpoint" },
      var.tags
    )
  }

  # Data source to get current region
  data "aws_region" "current" {}
