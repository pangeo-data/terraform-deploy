variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "test-cluster-change-name"
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

variable "use_private_subnets" {
    description = "Use private subnets for EKS worker nodes."
    type        = bool
    default = false
}

variable "public_subnets" {  
    description = "Public subnet IP ranges."
    type        = list(string)
    default = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
}

variable "private_subnets" {  
    description = "Private subnet IP ranges."
    type        = list(string)
    default = []   #   ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
}

variable "cidr" {
    description = "IP range of subnets"
    type = string
    default = "172.16.0.0/16"
}

variable "allowed_roles" {
    default = []
}
