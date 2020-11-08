output "public_ip" {
  value = aws_instance.my-first-instance.public_ip
  description = "public ip address"
}

output "alb_dns_name" {
  value = aws_lb.terraform-lb.dns_name
}