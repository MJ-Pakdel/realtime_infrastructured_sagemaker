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
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/24"]   # first /24 in the VPC
}
variable "tags" {
  type        = map(string)
  description = "Tags to apply to network resources"
  default     = {}
}
