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
data "aws_availability_zones" "Avaialble" {}

resource "aws_vpc" "VPC_TF" {
  cidr_block = "172.31.0.0/16"
  tags = {
    Name = "vpc_using_TF"
  }
}

# security group using terraform
resource "aws_security_group" "TF_SG" {
  name        = "SG using terraform"
  description = "security group using terraform"
  vpc_id      = aws_vpc.VPC_TF.id
  

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
  name          = "web_configuration"
  image_id      = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  security_groups            = [aws_security_group.TF_SG.id]

}

# creating AutoScaling group 
resource "aws_autoscaling_group" "example" {
  name                 = "TF-asg-example"
  launch_configuration = aws_launch_configuration.example.name
  min_size             = 1
  max_size             = 3
  vpc_zone_identifier  = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  lifecycle {
    create_before_destroy = true
  }
}

#Subnet Creation
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.VPC_TF.id
  cidr_block        = "172.31.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.VPC_TF.id
  cidr_block        = "172.31.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "subnet2"
  }
}

