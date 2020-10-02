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

# -------------------------------------------------------------------------
#                     Networking config 

variable vpc_cidr {
    description = "IP range of subnets"
    type = string
    # default = "172.16.0.0/16"
}

variable vpc_name {
   description = "Name of unmanaged VPC, e.g. created by IT department."
   type = string
}

variable private_subnet_names {
   description = "Patterns applied to Name tag to select unmanaged private subnets from the unmanaged vpc"
   type = list(string)
   default = ["*Private*"]
}

variable public_subnet_names {
   description = "Patterns applied to Name tag to select unmanaged public subnets from the unmanaged vpc"
   type = list(string)
   default = ["*Public*"]
}

variable cluster_endpoint_public_access_extra_cidrs {
   description = "Add other CIDRs for EKS API public endpoint access in addition to private subnet NAT EIPs."
   type = list(string)
   default = [ ]
}

variable cluster_sg_name {
   description = "Group added to EKS cluster granting access to API endpoint 443 to members of worker sg."
   type = string
}

variable worker_sg_name {
   description = "Group added to unmanaged workers.  Gives workers access to cluster 443 via the above, cluster access to workers, workers to workers."
   type = string
}

# ========================================================================
variable allowed_roles {
    default = []
}
