resource "aws_kms_key" "sops_key" {
  description = "Encryption key for secrets in CodeCommit repo ${var.repo_name}-secrets"
  tags        = {
    Terraform = "True",
    # TODO: pull this out into a variable
    Project = "roman-sit"
  }
}

resource "local_file" "sops-config" {
  filename = ".sops.yaml"
  content = <<EOF
creation_rules:
  - path_regex: .*
    kms: "${aws_kms_key.sops_key.arn}"
EOF
}


# upload .sops.yaml to S3; it will be downloaded later in the process

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.sops_s3_bucket
  acl    = "private"
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
  tags = {
    Env = "sandbox"
  }
}

resource "aws_s3_bucket_object" "sops-bucket" {
  bucket = var.sops_s3_bucket
  key    = var.sops_s3_key
  source = var.sops_s3_source
}
