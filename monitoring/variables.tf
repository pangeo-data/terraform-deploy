variable "profile" {
	default     = "terraform-bot"
  description = "the profile that the awscli will use to run commands."
}

variable "region" {
	default     = "us-east-1"
  description = "The availability region where your cluster is."
}

variable "cluster_name" {
  default     = "eks-cluster-example-name"
  description = "The name of the existing cluster."
}
