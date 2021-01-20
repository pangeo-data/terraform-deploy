terraform {
  required_version = ">= 0.13"
}

# Create IAM role + automatically make it available to cluster autoscaler service account
module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v3.3.0"
  create_role                   = false
  role_name                     = "${module.eks.cluster_id}-cluster-autoscaler"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cluster-autoscaler-service-account"]
}

data "aws_iam_policy" "cluster_autoscaler" {
  name = "${module.eks.cluster_id}-cluster-autoscaler-permissions"
}

resource "helm_release" "cluster-autoscaler" {
  name = "cluster-autoscaler"
  # Check that this is good, kube-system should already exist
  namespace = "kube-system"
  repository = "https://charts.helm.sh/stable/"
  chart = "cluster-autoscaler"
  version = "7.2.0"
  depends_on = [null_resource.kubectl_config]

  values = [
    file("cluster-autoscaler-values.yml")
  ]

  # Terraform keeps this in state, so we get it automatically!
  set{
    name = "awsRegion"
    value = var.region
  }

  set{
    name = "autoDiscovery.clusterName"
    value = module.eks.cluster_id
  }
}
