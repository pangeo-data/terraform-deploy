terraform {
  required_version = "~> 0.14.5"

  required_providers {
      aws = {
          source  = "hashicorp/aws"
          version = "~> 3.26.0"
      }
      template = {
          source  = "hashicorp/template"
          version = "~> 2.1"
      }
  }
}

provider "aws" {
  region  = var.region
}

resource "aws_codecommit_repository" "secrets_repo" {
  repository_name = var.repo_name
  description     = "kms encrypted secrets for JupyterHub deployment"
  tags            = {
    Owner = var.owner_tag,
    Terraform = "True"
  }
}
