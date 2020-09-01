variable "region" {
  default = "us-east-1"
}

variable "profile" {
  default = "terraform-bot"
}

variable "cluster_name" {
  default = "test-cluster-change-name"
}

variable "vpc_name" {
  default = "vpc-test-cluster-change-name"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)
  default = [ ]
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = [
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
  ]
}