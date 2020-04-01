# Put Prometheus and Grafana Helm releases on the support namespace

# This repo is already present as "stable"
#data "helm_repository" "default" {
#  name = "default"
#  url = "https://kubernetes-charts.storage.googleapis.com/"
#}

resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "kubernetes_storage_class" "prometheus-storageclass" {
  metadata {
    name      = "prometheus"
    #namespace = "prometheus"
  }

  storage_provisioner = "kubernetes.io/aws-ebs"
  reclaim_policy      = "Retain"
  mount_options       = ["debug"]
  parameters          = {
    type = "gp2"
  }
}

resource "helm_release" "prometheus" {
  name = "prometheus"
  namespace = kubernetes_namespace.prometheus.metadata.0.name
  repository = data.helm_repository.stable.metadata[0].name
  chart = "prometheus"
  #version = "0.11.0"

  values = [
    file("prometheus-values-min.yaml")
  ]
}

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

resource "helm_release" "grafana" {
  name = "grafana"
  namespace = kubernetes_namespace.grafana.metadata.0.name
  repository = data.helm_repository.stable.metadata[0].name
  chart = "grafana"
  depends_on = [helm_release.prometheus]
  #version = "0.11.0"

  values = [
    file("grafana-values-min.yaml")
  ]
}