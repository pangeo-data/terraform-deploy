resource "aws_iam_user" "hubploy_ecr_user" {
  name = "${var.cluster_name}-hubploy-ecr-pusher"
}

# FIXME: UHHHHHHHH, WHAT DOES THIS MEAN FOR OUR STATE FILES?!
# FIXME: WE SHOULD DEFINITELY MAYBE PUT A PGP KEY IN HERE
resource "aws_iam_access_key" "hubploy_ecr_user_secret_key" {
  user = aws_iam_user.hubploy_ecr_user.name
}

# FIXME: Support multiple images here
resource "aws_ecr_repository" "primary_user_image" {
  name                 = "${var.cluster_name}-user-image"
}