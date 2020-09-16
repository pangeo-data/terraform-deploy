locals {
       public_subnet_ids = tolist((data.aws_subnet_ids.public[*].ids)[0])
       public_subnet_cidrs = [for s in data.aws_subnet.public : s.cidr_block]
       public_subnet_names = [for s in data.aws_subnet.public : s.tags["Name"]]

       private_subnet_ids = tolist((data.aws_subnet_ids.private[*].ids)[0])
       private_subnet_cidrs = [for s in data.aws_subnet.private : s.cidr_block]
       private_subnet_names = [for s in data.aws_subnet.private : s.tags["Name"]]

       nat_ip_cidrs = [ for nat in data.aws_nat_gateway.nat_gateways : join("", [nat.public_ip, "/32"]) ]
       cluster_endpoint_public_access_cidrs = concat(local.nat_ip_cidrs, var.cluster_endpoint_public_access_extra_cidrs)
       vpc_id = data.aws_vpc.unmanaged[0].id
}
