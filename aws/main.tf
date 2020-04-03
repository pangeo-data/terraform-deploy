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
  version                = "~> 1.11.1"
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.6"

  name                 = "${var.cluster_name}-vpc"
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

      instance_type = "m5.large"
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

     instance_type = "m5.large"
     k8s_labels = {
       "hub.jupyter.org/node-purpose" =  "user"
     }
     additional_tags = {
     }
    }
  }


  map_roles    = var.map_roles
  map_accounts = var.map_accounts


  map_users = concat([{
    userarn  = aws_iam_user.hubploy_eks_user.arn
    username  = aws_iam_user.hubploy_eks_user.name
    # FIXME: Narrow these permissions down?
    groups   = ["system:masters"]
  }], var.map_users)
}

resource "aws_iam_user" "hubploy_eks_user" {
  name = "${var.cluster_name}-hubploy-eks"
}

resource "aws_iam_policy" "hubploy_eks_policy" {
  name = "${var.cluster_name}-hubploy-eks"
  description = "Just enough access to get EKS credentials"

  # FIXME: restrict this to just the EKS cluster we created
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "VisualEditor0",
          "Effect": "Allow",
          "Action": "eks:DescribeCluster",
          "Resource": "*"
      }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "hubploy_eks_user_policy_attachment" {
  user = aws_iam_user.hubploy_eks_user.name
  policy_arn = aws_iam_policy.hubploy_eks_policy.arn
}

# FIXME: UHHHHHHHH, WHAT DOES THIS MEAN FOR OUR STATE FILES?!
# FIXME: WE SHOULD DEFINITELY MAYBE PUT A PGP KEY IN HERE
resource "aws_iam_access_key" "hubploy_eks_user_secret_key" {
  user = aws_iam_user.hubploy_eks_user.name
}


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
