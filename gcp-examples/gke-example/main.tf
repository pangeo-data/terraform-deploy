provider "google" {
  credentials = file(var.credential_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
  version     = "~>v3.39.0"
}

module "vpc" {
  source = "terraform-google-modules/network/google"
  version = "~>2.3"

  project_id = var.project
  network_name = "${var.deployment_name}-network"

  subnets = [
    {
      subnet_name : ,
      subnet_ip : ,
      subnet_region : 
    }
  ]

  secondary_ranges = {
    var.subnet.name = [
      {
        range_name = 
        ip_cidr_range = 
      },
      {
        range_name = 
        ip_cidr_range = 
      },
    ]
  }
}

module "gke" {
  source = "terraform-google-modules/kubernetes-engine/google"
  project_id = 
  name = "${var.deployment_name}-cluster"
  network = module.vpc.network_name
  subnetwork = 
  ip_range_pods = 
  ip_range_services = 
  create_service_account = false
  remove_default_node_pool = true
  disable_legacy_metadata_endpoints = false
  #cluster_autoscaling = var.cluster_autoscaling

  node_pools = [
    {
      name = "scheduler-pool"
      machine_type = ""
      min_count = 
      max_count = 
      #service_account = var.compute_engine_service_account
      preemptible = true
    },
    {
      name = "worker-pool"
      machine_type = ""
      min_count = 
      max_count = 
      #service_account = var.compute_engine_service_account
      preemptible = true
    },
    {
      name = "gateway"
      machine_type = ""
      auto_upgrade = true
      initial_node_count = 
      preemptible = false
    }
  ]

  #node_pools_metadata = {}

  node_pools_labels = {
    all = {
      all-pools-example = true
      Owner = "Sebastian Alvis"
      Project = "gke-terraform-test-cluster"
    }
  }

  node_pool_taints = {
    all = [
      {
        key = all-pools-example
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
