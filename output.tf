output "vpc_id" {
  description = "this is the public IP"
  value       = aws_vpc.main.id
}

output "sg_id" {
  description = "this is the public IP"
  value       = aws_security_group.allow_tls.id
}

output "ec2_id" {
  description = "this is the public IP"
  value       = aws_instance.this[*].id
}