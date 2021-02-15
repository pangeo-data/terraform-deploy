terraform {
   backend "s3" {  
     # backend file expected to fill in here, vars not allowed 
   }
   required_version = "~> 0.14.5"
   required_providers {
      aws = {
          source  = "hashicorp/aws"
          version = "~> 3.26.0"
      }
      template = {
          source  = "hashicorp/template"
          version = "~> 2.1"
      }
      kubernetes = {
          source  = "hashicorp/kubernetes"
          version = "~> 1.11.1"
      }
      helm = {
          source  = "hashicorp/helm"
          version = "~> 2.0.2"
      }
      null = {
          source  = "hashicorp/null"
          version = "~> 3.0.0"
      }
   }
}

provider "aws" {
  region  = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
     host                   = data.aws_eks_cluster.cluster.endpoint
     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
     token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
