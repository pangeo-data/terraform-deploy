terraform {
  required_version = ">= 0.12.6"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = "us-east-1"
}

provider "template" {
  version = "~> 2.1"
}

data aws_availability_zones available {}

