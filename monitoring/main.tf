# General Setup
terraform {
  required_version = ">= 0.12.6"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
  profile = var.profile
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.10.0"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "helm_repository" "stable" {
  name = "stable"
  url = "https://kubernetes-charts.storage.googleapis.com"
}

# Prometheus Resources
resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "kubernetes_storage_class" "prometheus" {
  metadata {
    name      = "prometheus"
  }
  #namespace = kubernetes_namespace.prometheus.metadata.0.name
  storage_provisioner = "kubernetes.io/aws-ebs"
  reclaim_policy      = "Retain"
  parameters          = {
    type = "gp2"
  }
  #mount_options       = ["debug"]
}

resource "helm_release" "prometheus" {
  name = "prometheus"
  repository = data.helm_repository.stable.metadata[0].name
  namespace = kubernetes_namespace.prometheus.metadata.0.name
  chart = "prometheus"

  values = [
    file("../monitoring/prometheus-values.yaml")
  ]
}

# Grafana Resources
resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

resource "helm_release" "grafana" {
  name = "grafana"
  repository = data.helm_repository.stable.metadata[0].name
  namespace = kubernetes_namespace.grafana.metadata.0.name
  chart = "grafana"

  values = [
    file("../monitoring/grafana-values.yaml")
  ]

}
