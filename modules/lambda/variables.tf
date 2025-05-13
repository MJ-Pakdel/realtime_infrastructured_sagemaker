variable "name_prefix" {
  type = string
}
variable "lambda_memory" {
  type = number
}
variable "lambda_timeout" {
  type = number
}
variable "lambda_image_uri" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "security_group_id" {
  type = string
}
variable "lambda_role_arn" {
  type = string
}
variable "tags" {
  type = map(string)
  default = {}
}
