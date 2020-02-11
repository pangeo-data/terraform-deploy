terraform {
  required_version = ">= 0.12.6"
}

resource "random_password" "proxy_secret_token" {
  length = 64
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "helm_repository" "jupyterhub" {
  name = "jupyterhub"
  url = "https://jupyterhub.github.io/helm-chart/"
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
  }
}

resource "helm_release" "jupyterhub" {
  name = "staging"
  namespace = kubernetes_namespace.staging.metadata.0.name
  repository =data.helm_repository.jupyterhub.metadata[0].name
  chart = "jupyterhub"
  version = "0.9.0-beta.3.n023.h6a2b994"

  values =[
    file("values.yaml")
  ]

  # Terraform keeps this in state, so we get it automatically!
  set{
    name = "proxy.secretToken"
    value = random_password.proxy_secret_token.result
  }
}