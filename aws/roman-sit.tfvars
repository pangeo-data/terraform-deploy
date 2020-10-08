# Put your cluster where your data is
region = "us-east-1"

# Name of your cluster
cluster_name = "roman-sit"

allowed_roles = [
  "arn:aws:iam::328656936502:role/jupyterhub-admin",
]

permissions_boundary = "arn:aws:iam::328656936502:policy/Terraform-Perm-Boundary"

rolearn = "arn:aws:iam::328656936502:role/jupyterhub-admin"

username = "jupyterhub-admin"

# ============================================================================================================

# Configuration for unmanaged private subnets created by IT

vpc_name = "DEV-WF-SC-SB"   # "DEV-WF-SC-SB"

public_subnet_names = ["DEV-WF-SC-SB-Public-*"]  # ["DEV-WF-SC-SB-Public-*"]
private_subnet_names = ["DEV-WF-SC-SB-DMZ-*"]  # ["DEV-WF-SC-SB-DMZ-*"]

cluster_sg_name = "jmiller-cluster-sg"  # "user-cluster-sg" modeled after Additional worker sg
worker_sg_name = "jmiller-worker-sg"   # "user-worker-sg" modeled after Additional worker sg source group

