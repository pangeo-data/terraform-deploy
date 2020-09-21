# Attached to group
data "aws_iam_policy_document" "hubploy_eks" {
    statement {
        sid = "1"
        actions = [
          "eks:DescribeCluster"
        ]
        resources = [
          module.eks.cluster_arn
        ]
    }
}

# https://stackoverflow.com/questions/34922920/how-can-i-allow-a-group-to-assume-a-role
data "aws_iam_policy_document" "hubploy_assumptions" {
  statement {
    principals {
      type = "AWS"
      identifiers = var.allowed_roles
    }
    actions = [
      "sts:AssumeRole"
    ]

  }
}

resource "aws_iam_role" "hubploy_eks" {
  name = "${var.cluster_name}-hubploy-eks"
  assume_role_policy = data.aws_iam_policy_document.hubploy_assumptions.json
}

resource "aws_iam_policy" "hubploy_eks" {
  name = "${var.cluster_name}-hubploy-eks"
  description = "Just enough access to get EKS credentials"

  policy = data.aws_iam_policy_document.hubploy_eks.json
}

resource "aws_iam_role_policy_attachment" "hubploy_eks" {
  role       = aws_iam_role.hubploy_eks.name
  policy_arn = aws_iam_policy.hubploy_eks.arn
}

resource "aws_iam_role" "hubploy_ecr" {
  name = "${var.cluster_name}-hubploy-ecr"
  assume_role_policy = data.aws_iam_policy_document.hubploy_assumptions.json
}

resource "aws_iam_role_policy_attachment" "hubploy_ecr_policy_attachment" {
  role = aws_iam_role.hubploy_ecr.name
  # FIXME: Restrict resources to the ECR repository we created
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
