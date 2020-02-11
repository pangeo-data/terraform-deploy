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

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.10.0"
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.6"

  name                 = var.vpc_name
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  # We can use private subnets too once https://github.com/aws/containers-roadmap/issues/607
  # is fixed
  public_subnets       = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  enable_dns_hostnames = true

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
  # FIXME: We can use private subnets once https://github.com/aws/containers-roadmap/issues/607
  # is fixed
  subnets      = module.vpc.public_subnets
  vpc_id       = module.vpc.vpc_id

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  node_groups = {
    core = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "m5.large"
      k8s_labels    = {
        "hub.jupyter.org/node-purpose" =  "core"
      }

      additional_tags = {
      }
    }
    #notebook = {
    #  desired_capacity = 1
    #  max_capacity     = 10
    #  min_capacity     = 1

    #  instance_type = "m5.xlarge"
    #  k8s_labels = {
    #    "hub.jupyter.org/node-purpose" =  "user"
    #  }
    #  additional_tags = {
    #  }
    #}
  }

  worker_groups_launch_template = [
    {
      name                    = "user-spot"
      override_instance_types = ["m5.2xlarge", "m4.2xlarge"]
      spot_instance_pools     = 2
      asg_max_size            = 100
      asg_desired_capacity    = 0

      # Use this to set labels / taints
      kubelet_extra_args = <<EOT
                            --node-taints=hub.jupyter.org/dedicated=user:NoSchedule
                            --node-labels=node-role.kubernetes.io/user=user
                            --node-labels=hub.jupyter.org/node-purpose=user
                            EOT

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
        }
      ]
    },
    {
      name                    = "worker-spot"
      override_instance_types = ["r5.2xlarge", "r4.2xlarge"]
      spot_instance_pools     = 2
      asg_max_size            = 100
      asg_desired_capacity    = 0

      # Use this to set labels / taints
      kubelet_extra_args = <<EOT
                            --node-taints=k8s.dask.org/dedicated=worker:NoSchedule
                            --node-labels=node-role.kubernetes.io/worker=worker
                            --node-labels=k8s.dask.org/node-purpose=worker
                            EOT

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
        }
      ]
    }
  ]

  map_roles    = var.map_roles
  map_users    = var.map_users
  map_accounts = var.map_accounts
}