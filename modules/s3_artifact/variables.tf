variable "name_prefix" {
  description = "Project prefix used for naming the bucket"
  type        = string
}

variable "tags" {
  description = "Tags applied to the bucket"
  type        = map(string)
  default     = {}
}

variable "account_id" {
  description = "AWS account ID for resource ARNs"
  type        = string
}
