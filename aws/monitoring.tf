resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "kubernetes_storage_class" "prometheus-storageclass" {
  metadata {
    name      = "prometheus"
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
  version = "~11.2.1"

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
  version = "~5.0.24"

  values = [
    file("grafana-values-min.yaml")
  ]

  set {
    name = "adminUser"
    value = var.grafana_admin
  }

  set {
    name = "adminPassword"
    value = var.grafana_password
  }
} 