# Providers
terraform {
  required_version = ">= 0.12.6"
}

provider "aws" {
  version = ">= 2.57"
  region  = var.region
  profile = var.profile
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.4"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

# VPC
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>2.44"
  name    = "${var.deployment_name}vpc"

  cidr            = "10.0.0.0/16"
  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = {
    "kubernetes.io/cluster/${var.deployment_name}cluster" = "shared"
  }
}

# Kubernetes
# After this is created, will need to set kubeconfig to look at this.
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

# EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "${var.deployment_name}cluster"
  cluster_version = "1.15"

  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  enable_irsa     = true

  cluster_endpoint_private_access = true

  #tags = {}

  worker_groups = [
    {
      name                  = "core"
      asg_max_size          = 1
      asg_min_size          = 1
      asg_desired_capacity  = 1
      instance_type         = "t3.xlarge"
      subnets               = [module.vpc.private_subnets[0]]

      # Use this to set labels / taints
      kubelet_extra_args    = "--node-labels=node-role.kubernetes.io/core=core,hub.jupyter.org/node-purpose=core"
      
      #tags = {}
    },
    {
      name               = "user"
      instance_type      = "m5.2xlarge"

      # Use this to set labels / taints
      kubelet_extra_args = "--node-labels=node-role.kubernetes.io/user=user,hub.jupyter.org/node-purpose=user"
    }
  ]
}
