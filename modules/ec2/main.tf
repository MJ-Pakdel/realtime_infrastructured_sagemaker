###############################################
# EC2 latency‑tester module
###############################################

########## Data: latest Amazon Linux 2 AMI ##########
data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

########## EC2 Instance ##########
resource "aws_instance" "tester" {
  ami                         = data.aws_ami.amazon_linux2.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null
  iam_instance_profile        = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  user_data = <<-USERDATA
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y python3.8
              yum install -y git
              pip3 install --upgrade pip
              pip3 install requests numpy
              USERDATA

  tags = {
    Name = var.instance_name
  }
}
