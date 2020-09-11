terraform {
  required_version = ">= 0.12.6"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}

provider "template" {
  version = "~> 2.1"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11.1"
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.6"

  name                 = "${var.cluster_name}-vpc"
  cidr                 = var.cidr
  azs                  = data.aws_availability_zones.available.names
  # We can use private subnets too once https://github.com/aws/containers-roadmap/issues/607
  # is fixed
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = var.use_private_subnets
  single_nat_gateway   = var.use_private_subnets
  
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.cluster_name
  subnets      = var.use_private_subnets ? module.vpc.private_subnets : module.vpc.public_subnets
  cluster_endpoint_private_access = true
  vpc_id       = module.vpc.vpc_id
  enable_irsa  = true


  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  node_groups = {
    core = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t3.small"
      k8s_labels    = {
        "hub.jupyter.org/node-purpose" =  "core"
      }
      additional_tags = {
      }
    }
    notebook = {
     desired_capacity = 1
     max_capacity     = 10
     min_capacity     = 1

     instance_type = "t3.medium"
     k8s_labels = {
       "hub.jupyter.org/node-purpose" =  "user"
     }
     additional_tags = {
     }
    }
  }


  map_accounts = var.map_accounts
  #map_users = var.map_users


  map_roles = concat([{
    rolearn  = aws_iam_role.hubploy_eks.arn
    username = aws_iam_role.hubploy_eks.name
    # FIXME: Narrow these permissions down?
    groups   = ["system:masters"]
  }], var.map_roles)
}


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
