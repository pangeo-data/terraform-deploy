resource "aws_instance" "ecs-optimized" {
  ami                    = "ami-014a2e30da708ee8b"
  instance_type          = "t3a.medium"
  key_name               = "${var.name_prefix}bastion-instance"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ecs-test.id,
                            aws_security_group.home_dirs_sg.id]
  user_data              = file("mount_volume.sh")
  tags = {
    Name = "${var.name_prefix}efs-mount"
    Owner = split("/", data.aws_caller_identity.current.arn)[1]
    AutoTag_Creator = data.aws_caller_identity.current.arn
  }
}

resource "aws_security_group" "ecs-test" {
  name        = "${var.name_prefix}ecs-test"
  description = "Allow SSH"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # Don't leave open for long periods of time
    cidr_blocks = ["0.0.0.0/0", "71.197.186.34/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Owner = split("/", data.aws_caller_identity.current.arn)[1]
    AutoTag_Creator = data.aws_caller_identity.current.arn
  }
}
