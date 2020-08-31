resource "local_file" "hubploy_yaml" {
  filename = "hubploy.yaml"
  content = <<EOF
images:
  image_name: ${aws_ecr_repository.primary_user_image.repository_url}

  registry:
    provider: aws
    aws:
      zone: ${var.region}
      service_key: # FIXME: Use role assumpmtions when hubploy supports them
      project: ${data.aws_caller_identity.current.account_id}


cluster:
  provider: aws
  aws:
      zone: ${var.region}
      service_key: # FIXME: Use role assumpmtions when hubploy supports them
      cluster: ${module.eks.cluster_id}
EOF
}