data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.1.0"

  cluster_name = var.cluster_name
  cluster_version = var.cluster_version

  subnets      = local.private_subnet_ids

  cluster_endpoint_public_access = false
  cluster_endpoint_private_access = true

  # Sets additional worker security groups on console.
  cluster_create_security_group = false
  cluster_security_group_id = data.aws_security_group.cluster_sg.id
  vpc_id       = local.vpc_id
  enable_irsa  = true

  worker_create_security_group = true
  worker_security_group_id = data.aws_security_group.worker_sg.id

  manage_cluster_iam_resources = false
  manage_worker_iam_resources = false
  workers_role_name = data.aws_iam_role.worker_role.name
  cluster_iam_role_name = data.aws_iam_role.cluster_role.name

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 150
  }

  node_groups = {
    core = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["t3.small"]
      k8s_labels    = {
        "hub.jupyter.org/node-purpose" =  "core"
      }
      additional_tags = {
      }
      iam_role_arn = data.aws_iam_role.worker_role.arn
    }
    notebook = {
     desired_capacity = 1
     max_capacity     = 10
     min_capacity     = 1

     instance_types = [var.notebook_instance_type]
     k8s_labels = {
       "hub.jupyter.org/node-purpose" =  "user"
     }
     additional_tags = {
     }
     iam_role_arn = data.aws_iam_role.worker_role.arn
    }
  }

  map_accounts = var.map_accounts
  map_users = var.map_users

  map_roles = concat([{
    rolearn  = var.rolearn
    username = var.username
    # FIXME: Narrow these permissions down?
    groups   = ["system:masters"]
  }], var.map_roles)

}

data aws_iam_role "worker_role" {
   name = "${var.cluster_name}-worker"
}

data aws_iam_role "cluster_role" {
   name = "${var.cluster_name}-cluster"
}

resource "null_resource" "kubectl_config" {
  depends_on = [module.eks]
  provisioner "local-exec" {
     command="aws eks update-kubeconfig --name ${var.cluster_name} --role-arn ${var.rolearn}"
  }
}
