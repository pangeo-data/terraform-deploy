# Attached to deployers group to let them assume the role we need
# Attached to hubploy-deployer role as well
data "aws_iam_policy_document" "hubploy_deployers" {
  statement {
    sid = "1"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
        aws_iam_role.hubploy_eks.arn,
        aws_iam_role.hubploy_ecr.arn
    ]
  }
}

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
      identifiers = [
          # Very icky, but see https://stackoverflow.com/questions/34922920/how-can-i-allow-a-group-to-assume-a-role
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
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

resource "aws_iam_policy" "hubploy_deployers" {
  name = "${var.cluster_name}-hubploy-deployers"

  policy = data.aws_iam_policy_document.hubploy_deployers.json
}
resource "aws_iam_group" "hubploy_deployers" {
    name = "${var.cluster_name}-hubploy-deployers"
}
resource "aws_iam_group_policy_attachment" "hubploy_deployers" {
  group       = aws_iam_group.hubploy_deployers.name
  policy_arn = aws_iam_policy.hubploy_deployers.arn
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


data "aws_iam_policy_document" "hubploy_deployer_ec2_policy" {
  statement {
    sid = "1"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
        type = "Service"
        identifiers = [
            "ec2.amazonaws.com"
        ]
    }
  }
}

resource "aws_iam_role" "hubploy_deployer" {
  name = "${var.cluster_name}-hubploy-deployer"
  assume_role_policy = data.aws_iam_policy_document.hubploy_deployer_ec2_policy.json
}

resource "aws_iam_policy" "hubploy_deployer" {
  name = "${var.cluster_name}-hubploy-deployer"
  policy = data.aws_iam_policy_document.hubploy_deployers.json
}

resource "aws_iam_role_policy_attachment" "hubploy_deployer" {
  role       = aws_iam_role.hubploy_deployer.name
  policy_arn = aws_iam_policy.hubploy_deployer.arn
}
