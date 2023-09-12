terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# Configure the AWS Provider
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

locals {
  project_name = "Web-cluster"
}



# VPC Creation
data "aws_vpc" "default" {
  default = true
}

# security group using terraform
resource "aws_security_group" "TF_SG" {
  name        = "SG using terraform"
  description = "security group using terraform"
  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "TF_SG"
  }
}




# Creating Launch configuration
resource "aws_launch_configuration" "example" {
  name            = "web_configuration"
  image_id        = "ami-053b0d53c279acc90"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.TF_SG.id]

}

# create Subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# creating AutoScaling group 
resource "aws_autoscaling_group" "example" {
  name                 = "TF-asg-example"
  launch_configuration = aws_launch_configuration.example.name
  min_size             = 1
  max_size             = 3
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns    = [aws_alb_target_group.TF_tg.arn]

  lifecycle {
    create_before_destroy = true
  }
}



# Application laod balancer
resource "aws_alb" "TF_example" {
  name            = "example-alb"
  subnets         = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb_sg.id]
}


# create a listner for the alb
resource "aws_lb_listener" "TF_http" {
  load_balancer_arn = aws_alb.TF_example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404:page not found"
      status_code  = "404"
    }
  }
}


# create a security group for ALB
resource "aws_security_group" "alb_sg" {
  name = "TF-example-alb"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Create a target group
resource "aws_alb_target_group" "TF_tg" {
  name     = "TF-example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}



# Create a listener rules
resource "aws_lb_listener_rule" "TF_listnerRules" {
  listener_arn = aws_lb_listener.TF_http.arn
  priority    = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.TF_tg.arn
  }
}