variable "region" {
  default = "us-east-1"
}

variable "repo_name" {
  description = "Name of the CodeCommit repository"
  type = string
}

variable "sops_s3_bucket" {
  description = "Name of secrets S3 bucket"
  type = string
}

variable "sops_s3_key" {
  description = "The .sops.yaml file"
  type = string
}

variable "sops_s3_source" {
  description = "The .sops.yaml file"
  type = string
}

variable "owner_tag" {
  description = "This is for ITSD to track ownership"
  type = string
}
