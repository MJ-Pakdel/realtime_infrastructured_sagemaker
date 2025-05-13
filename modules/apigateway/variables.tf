variable "name_prefix" {
  type = string
}
variable "lambda_function_name" {
  type = string
}
variable "lambda_invoke_arn" {
  type = string
}
variable "lambda_function_arn" {
  type = string
}
variable "region" {
  type = string
}
variable "tags" {
  type = map(string)
  default = {}
}
