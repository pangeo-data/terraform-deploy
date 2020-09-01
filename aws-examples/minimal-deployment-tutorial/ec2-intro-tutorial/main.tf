terraform {
  required_version = ">= 0.12.6"
}

provider "aws" {
  version = ">= 2.57"
  region  = var.region
  profile = var.profile
}

data "aws_ami" "ubuntu" {
  most_recent      = true
  owners           = ["self"]
  executable_users = ["self"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.040amd64-server-*"]
  }
}

resource "aws_instance" "test-ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "${var.deployment_name}"
  }
}

