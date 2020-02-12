terraform {
  required_version = ">= 0.12.6"
}

resource "helm_release" "cluster-autoscaler" {
  name = "cluster-autoscaler"
  # Check that this is good, kube-system should already exist
  namespace = "kube-system"
  repository = data.helm_repository.stable.metadata[0].name
  chart = "cluster-autoscaler"

  values = [
    file("cluster-autoscaler-values.yml")
  ]
}