# =======================================================================

data aws_vpc unmanaged {
  count =  1
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]	# can be patterns
  }
}

data aws_nat_gateway nat_gateways {
   count = length(local.public_subnet_ids)
   subnet_id = local.public_subnet_ids[count.index]
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

