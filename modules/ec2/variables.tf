########## Variables ##########

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "latency-tester"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Public subnet ID in which to launch the instance"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "One or more security groups to attach"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "SSH key‑pair name (blank to disable SSH login)"
  type        = string
  default     = ""
}

variable "iam_instance_profile" {
  description = "Name of the IAM instance profile to attach (for SSM access)"
  type        = string
  default     = ""
}
