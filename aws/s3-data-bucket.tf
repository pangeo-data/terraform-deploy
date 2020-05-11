# S3 bucket
resource "aws_s3_bucket" "hackweek-data-bucket" {
  bucket = "icesat2hack2020"
  acl    = "private"

  tags = {
    Owner = split("/", data.aws_caller_identity.current.arn)[1]
    AutoTag_Creator = data.aws_caller_identity.current.arn
  }
}

# bucket access policy
resource "aws_iam_policy" "hackweek-bucket-access-policy" {
    name        = "icesat2-hackweek-data-bucket-access-policy"
    path        = "/"
    description = "Permissions for Terraform-controlled EKS cluster creation and management"
    policy      = data.aws_iam_policy_document.hackweek-bucket-access-permissions.json
}

# bucket access policy data
data "aws_iam_policy_document" "hackweek-bucket-access-permissions" {
  version = "2012-10-17"

  statement {
    sid       = "icesat2hackweekDataBucketListAccess"

    effect    = "Allow"

    actions   = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.hackweek-data-bucket.arn
    ]
  }

  statement {
    sid       = "icesat2hackweekDataBucketReadWriteAccess"

    effect    = "Allow"

    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.hackweek-data-bucket.arn}/*"
    ]
  }
}

# bucket access role and service account for jupyterhub
module "iam_assumable_role_bucket_access" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.6.0"
  create_role                   = true
  role_name                     = "icesat2-hackweek-bucket-access-serviceaccount"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.hackweek-bucket-access-policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:hackweek-hub-staging:default",
                                   "system:serviceaccount:hackweek-hub-prod:default"]

  tags = {
    Owner = split("/", data.aws_caller_identity.current.arn)[1]
    AutoTag_Creator = data.aws_caller_identity.current.arn
  }
}