terraform {
  required_version = ">= 0.12.6"
}

provider "aws" {
  version = ">= 2.57"
  region  = var.region
  profile = var.profile
}

data "aws_ami" "amazon-linux" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami*2018.03.0.2*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "test-ec2" {
  ami           = data.aws_ami.amazon-linux.id
  instance_type = "t2.micro"

  tags = {
    Name = "${var.deployment_name}"
  }
}

