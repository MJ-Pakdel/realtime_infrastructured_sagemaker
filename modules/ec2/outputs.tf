########## Outputs ##########

output "instance_id" {
  description = "ID of the latency‑tester EC2 instance"
  value       = aws_instance.tester.id
}

output "public_ip" {
  description = "Public IP address of the latency‑tester EC2"
  value       = aws_instance.tester.public_ip
}