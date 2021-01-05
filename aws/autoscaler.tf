terraform {
  required_version = ">= 0.13"
}

# Create IAM role + automatically make it available to cluster autoscaler service account
module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v3.3.0"
  create_role                   = true
  role_name                     = "${module.eks.cluster_id}-cluster-autoscaler"
  role_permissions_boundary_arn = var.permissions_boundary
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:eluster-autoscaler-service-account"]
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
	]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerIAM"
    effect = "Allow"

    actions = [
      "iam:GetRole",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
   ]	

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "autoscaler-attach" {
  role = "${module.eks.cluster_id}-cluster-autoscaler"
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "helm_release" "cluster-autoscaler" {
  name = "cluster-autoscaler"
  # Check that this is good, kube-system should already exist
  namespace = "kube-system"
  repository = data.helm_repository.stable.metadata[0].name
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
