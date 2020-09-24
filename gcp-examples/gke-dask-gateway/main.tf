terraform {
  required_version = ">= 0.12.6"
}

provider "google-beta" {
  credentials = var.credential_file
  project     = var.project
  region      = var.region
  zone        = var.zone
  version     = "~>v3.39.0"
}

provider "google" {
  credentials = var.credential_file
  project     = var.project
  region      = var.region
  zone        = var.zone
}

module "vpc" {
  source = "terraform-google-modules/network/google"
  version = "~>2.3"

  project_id = var.project
  network_name = "${var.deployment_name}-network"

  subnets = [
    {
      subnet_name = "${var.deployment_name}-subnet-0",
      subnet_ip = "10.0.0.0/16",
      subnet_region = var.region
    }
  ]

  secondary_ranges = {
    "${var.deployment_name}-subnet-0" = [
      {
        range_name = "us-west2-gke-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name = "us-west2-gke-services"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

module "gke" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster"
  project_id = var.project
  name = "${var.deployment_name}-cluster"
  region = var.region
  #zone = var.zone
  network = module.vpc.network_name
  subnetwork = module.vpc.subnets_names[0]
  ip_range_pods = "us-west2-gke-pods"
  ip_range_services = "us-west2-gke-services"
  create_service_account = false
  remove_default_node_pool = true
  disable_legacy_metadata_endpoints = false
  #cluster_autoscaling = var.cluster_autoscaling

  node_pools = [
    {
      name = "scheduler-pool"
      machine_type = "n1-standard-8"
      min_count = 0
      max_count = 2
      #service_account = var.compute_engine_service_account
      preemptible = true
    },
    {
      name = "worker-pool"
      machine_type = "n1-standard-8"
      min_count = 0
      max_count = 40
      #service_account = var.compute_engine_service_account
      preemptible = true
    },
    {
      name = "gateway"
      machine_type = "n1-standard-8"
      auto_upgrade = true
      initial_node_count = 1
      preemptible = false
    }
  ]

  #node_pools_metadata = {}

  node_pools_labels = {
    all = {
      all-pools-example = true,
      Owner = "salvis",
      Project = "gke-terraform-test-cluster",
    }
  }

  node_pools_taints = {
    all = [
      {
        key = "all-pools-example"
        value = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
    scheduler-pool = [
      {
        key = "k8s.dask.org/dedicated"
        value = "scheduler"
        effect = "NO_SCHEDULE"
      },
    ]
    worker-pool = [
      {
        key = "k8s.dask.org/dedicated"
        value = "worker"
        effect = "NO_SCHEDULE"
      },
    ]
  }
}

resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "terraform-clusterrole-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-adminm"
  }
  subject {
    kind = "User"
    name = "admin"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind = "ServiceAccount"
    name = "default"
    namespace = "kube-system"
  }
  subject {
    kind = "Group"
    name = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}
