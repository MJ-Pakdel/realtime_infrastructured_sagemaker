# ECR Repository for container images
# Terraform AWS ECR Repository resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
resource "aws_ecr_repository" "this" {
  name                 = "${var.name_prefix}-ecr"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
  force_delete = true
  tags = merge(
    { Name = "${var.name_prefix}-ecr-repo" },
    var.tags
  )
}
