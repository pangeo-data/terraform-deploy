# =======================================================================

data aws_vpc unmanaged {
  count =  1
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]	# can be patterns
  }
}

data aws_subnet_ids private {
  vpc_id = local.vpc_id
  filter {
    name   = "tag:Name"
    values = var.private_subnet_names	# can be patterns
  }
}

data aws_subnet private {
   for_each = data.aws_subnet_ids.private.ids
   id       = each.value
}

data aws_subnet_ids public {
  vpc_id = local.vpc_id
  filter {
    name   = "tag:Name"
    values = var.public_subnet_names	# can be patterns
  }
}

data aws_subnet public {
   for_each = data.aws_subnet_ids.public.ids
   id       = each.value
}

data aws_security_group cluster_sg {
  filter {
    name   = "tag:Name"
    values = [var.cluster_sg_name]
  }
}

data aws_security_group worker_sg {
  filter {
    name   = "tag:Name"
    values = [var.worker_sg_name]
  }
}

# aws ec2 create-tags

resource "null_resource" "vpc_tag" {
  provisioner "local-exec" {
    command="aws ec2 create-tags --resources ${local.vpc_id} --tags Key=kubernetes.io/cluster/${var.cluster_name},Value=shared"
  }
}

resource "null_resource" "public_subnet_tags_shared" {
  provisioner "local-exec" {
     command="aws ec2 create-tags --resources ${local.public_subnet_ids_str}   --tags Key=kubernetes.io/cluster/${var.cluster_name},Value=shared"
  }
}

resource "null_resource" "public_subnet_tags_elb" {
  provisioner "local-exec" {
     command="aws ec2 create-tags --resources ${local.public_subnet_ids_str}   --tags Key=kubernetes.io/role/elb,Value=1"
  }
}

resource "null_resource" "private_subnet_tags_shared" {
  provisioner "local-exec" {
     command="aws ec2 create-tags --resources ${local.private_subnet_ids_str}  --tags Key=kubernetes.io/cluster/${var.cluster_name},Value=shared"
  }
}

resource "null_resource" "private_subnet_tags_internal_elb" {
  provisioner "local-exec" {
     command="aws ec2 create-tags --resources ${local.private_subnet_ids_str}  --tags Key=kubernetes.io/role/internal-elb,Value=1"
  }
}

