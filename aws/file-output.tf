resource "local_file" "hubploy_ecr_user_creds" {
  filename = "aws-ecr-creds.cfg"
  content = <<EOF
[default]
aws_access_key_id = ${aws_iam_access_key.hubploy_ecr_user_secret_key.id}
aws_secret_access_key = ${aws_iam_access_key.hubploy_ecr_user_secret_key.secret}
EOF
}

resource "local_file" "hubploy_eks_user_creds" {
  filename = "aws-eks-creds.cfg"
  content = <<EOF
[default]
aws_access_key_id = ${aws_iam_access_key.hubploy_eks_user_secret_key.id}
aws_secret_access_key = ${aws_iam_access_key.hubploy_eks_user_secret_key.secret}
EOF
}

resource "local_file" "hubploy_yaml" {
  filename = "hubploy.yaml"
  content = <<EOF
images:
  image_name: ${aws_ecr_repository.primary_user_image.repository_url}

  registry:
    provider: aws
    aws:
      zone: ${var.region}
      service_key: aws-ecr-creds.cfg
      project: # FILL ME IN FOR NOW


cluster:
  provider: aws
  aws:
      zone: ${var.region}
      service_key: aws-eks-creds.cfg
      cluster: ${module.eks.cluster_id}
EOF
}