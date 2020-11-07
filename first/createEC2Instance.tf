provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "my-first-instance" {
  ami = "ami-0817d428a6fb68645"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.security_group.id]

  user_data = <<-EOF
              !#/bin/bash
              echo "Hello World!" >> index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  tags = {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "security_group" {

  name = "terraform-security-group"

  ingress {
    from_port = var.server_port
    protocol = "tcp"
    to_port = var.server_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server_port" {
  description = "server port"
  default = 8080
  type = number
}

output "public_ip" {
  value = aws_instance.my-first-instance.public_ip
  description = "public ip address"
}