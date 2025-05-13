variable "name_prefix" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "instance_count" {
  type = number
}
# VPC configuration removed - not needed when SageMaker is outside VPC
# variable "subnet_ids" {
#   type = list(string)
# }
# variable "security_group_id" {
#   type = string
# }
variable "sagemaker_role_arn" {
  type = string
}
variable "sagemaker_image_uri" {
  type = string
}
variable "model_s3_path" {
  description = "Full S3 URI to model.tar.gz"
  type        = string
}
variable "tags" {
  type = map(string)
  default = {}
}
