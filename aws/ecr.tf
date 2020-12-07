# FIXME: Support multiple images here
resource "aws_ecr_repository" "primary_user_image" {
  name = "${var.cluster_name}-user-image"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
