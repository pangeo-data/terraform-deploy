terraform {
  required_version = ">= 0.12.6"
}

data "helm_repository" "eks" {
  name = "eks"
  url  = "https://aws.github.io/eks-charts"
}

resource "helm_release" "aws-node-termination-handler" {
  name       = "aws-node-termination-handler"
  namespace  = "kube-system"
  repository = data.helm_repository.eks.metadata[0].name
  chart      = "aws-node-termination-handler"

  set{
    name  = "serviceAccount.name"
    value = "iamserviceaccount-${var.name_prefix}aws-node-termination-handler"
  }
}