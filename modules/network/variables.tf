variable "name_prefix" {
  type        = string
  description = "Name prefix to use for network resources"
}
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}
variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for private subnets"
}
variable "tags" {
  type        = map(string)
  description = "Tags to apply to network resources"
  default     = {}
}
