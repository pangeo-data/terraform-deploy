terraform {
  required_version = ">= 0.12.6"

  backend "s3" {
    #bucket         = "hackweek-terraform-state-bucket"
    key            = "hackweek-cluster-config.tfstate"
    region         = "us-west-2"
    encrypt        = true
  }
}

provider "aws" {
  version = "2.59.0"
  region  = var.region
  profile = var.profile
}

provider "template" {
  version = "~> 2.1"
}

data "aws_caller_identity" "current" {}

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
  version                = "~> 1.11.1"
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.6"

  name                 = "${var.name_prefix}vpc"
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names

  public_subnets       = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  private_subnets      = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = {
    "kubernetes.io/cluster/${module.eks.cluster_id}" = "shared"
    Owner = split("/", data.aws_caller_identity.current.arn)[1]
    AutoTag_Creator = data.aws_caller_identity.current.arn
    Project = "${var.name_prefix}project"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${module.eks.cluster_id}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${module.eks.cluster_id}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "${var.name_prefix}cluster"
  cluster_version = "1.15"
  version         = "11.1.0"

  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  enable_irsa     = true

  cluster_endpoint_private_access = true

  tags = {
    Owner = split("/", data.aws_caller_identity.current.arn)[1]
    AutoTag_Creator = data.aws_caller_identity.current.arn
    Project = "${var.name_prefix}project"
  }

  workers_group_defaults = {
    ami_id = "ami-065418523a44331e5"
  }

  worker_groups = [

  ]

  worker_groups_launch_template = [
    {
      name                    = "core-spot"
      asg_max_size            = 1
      asg_min_size            = 1
      asg_desired_capacity    = 1
      instance_type           = ["t3a.xlarge", "t3a.xlarge"]
      spot_instance_pools     = 2
      subnets                 = [module.vpc.private_subnets[0]]

      # Use this to set labels / taints
      kubelet_extra_args      = "--node-labels=role=core,hub.jupyter.org/node-purpose=core"
      
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${module.eks.cluster_id}"
          "propagate_at_launch" = "false"
          "value"               = "true"
        }
      ]
    },
    {
      name                    = "user-spot"
      override_instance_types = ["m5.2xlarge", "m4.2xlarge", "m5a.2xlarge"]
      spot_instance_pools     = 3
      asg_max_size            = 100
      asg_min_size            = 0
      asg_desired_capacity    = 0

      # Use this to set labels / taints
      kubelet_extra_args = "--node-labels=role=user,hub.jupyter.org/node-purpose=user --register-with-taints hub.jupyter.org/dedicated=user:NoSchedule"

      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/node-template/label/hub.jupyter.org/node-purpose" 
          "propagate_at_launch" = "false"
          "value"               = "user"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/node-template/taint/hub.jupyter.org/dedicated" 
          "propagate_at_launch" = "false"
          "value"               = "user:NoSchedule"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${module.eks.cluster_id}"
          "propagate_at_launch" = "false"
          "value"               = "true"
        }
      ]
    },
    {
      name                    = "worker-spot"
      override_instance_types = ["r5.2xlarge", "r4.2xlarge"]
      spot_instance_pools     = 2
      asg_max_size            = 100
      asg_min_size            = 0
      asg_desired_capacity    = 0

      # Use this to set labels / taints
      kubelet_extra_args = "--node-labels=role=worker,k8s.dask.org/node-purpose=worker --register-with-taints k8s.dask.org/dedicated=worker:NoSchedule"

      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/node-template/label/k8s.dask.org/node-purpose" 
          "propagate_at_launch" = "false"
          "value"               = "worker"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/node-template/taint/k8s.dask.org/dedicated" 
          "propagate_at_launch" = "false"
          "value"               = "worker:NoSchedule"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${module.eks.cluster_id}"
          "propagate_at_launch" = "false"
          "value"               = "true"
        }
      ]
    }
  ]

  map_roles    = var.map_roles
  map_users    = var.map_users
  map_accounts = var.map_accounts
}


provider "helm" {
  version = "~> 1.1"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
