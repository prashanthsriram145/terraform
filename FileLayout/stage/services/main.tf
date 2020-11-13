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
              ${data.terraform_remote_state.db.outputs.address} >> index.html
              ${data.terraform_remote_state.db.outputs.port} >> index.html
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

resource "aws_launch_configuration" "launch_config" {
  image_id = "ami-0817d428a6fb68645"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.security_group.id]

  user_data = <<-EOF
              !#/bin/bash
              echo "Hello World!" >> index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "scaling_group" {
  max_size = 10
  min_size = 2

  launch_configuration = aws_launch_configuration.launch_config.name
  vpc_zone_identifier = data.aws_subnet_ids.subnet_ids.ids
  target_group_arns = [aws_alb_target_group.terraform-target-group.arn]
  health_check_type = "ELB"

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "terraform_asg_example"
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.aws_vpc.default_vpc.id
}

resource "aws_lb" "terraform-lb" {
  subnets = data.aws_subnet_ids.subnet_ids.ids
  load_balancer_type = "application"
  name = "terraform-load-balancer"
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "terraform-lb-listener" {
  load_balancer_arn = aws_lb.terraform-lb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = "404"
    }
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb_target_group" "terraform-target-group" {
  name = "terraform-target-group"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "terraform-listener-rule" {
  listener_arn = aws_lb_listener.terraform-lb-listener.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.terraform-target-group.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "terraform-up-and-running-spk-145"
    key = "stage/data-stores/terraform.tfstate"
    region = "us-east-1"
  }
}