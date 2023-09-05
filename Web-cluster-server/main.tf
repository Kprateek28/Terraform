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

# security group using terraform
resource "aws_security_group" "TF_SG" {
  name        = "SG using terraform"
  description = "security group using terraform"
  vpc_id      = "vpc-0ba927b9e38633b0c"

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

  

# Create a ec2 instance
resource "aws_instance" "web-server" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.TF_SG.name]
  
  tags = {
    Name = "Server-${local.project_name}"
  }
}







output "instance_ip_addr" {
  value = aws_instance.web-server.public_ip

}
