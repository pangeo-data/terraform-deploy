terraform {
   required_version = "~> 0.14.5"
   required_providers {
      provider "aws" {
          source  = "hashicorp/aws"
          version = "~> 3.26.0"
          region  = var.region
      }
      provider "template" {
          source  = "hashicorp/template"
          version = "~> 2.1"
      }
      provider "kubernetes" {
          source                 = "hashicorp/kubernetes"
          version                = "~> 1.11.1"
          host                   = data.aws_eks_cluster.cluster.endpoint
          cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
          token                  = data.aws_eks_cluster_auth.cluster.token
          load_config_file       = false
      }
      provider "helm" {
          source = "hashicorp/helm"
          version = "~> 2.0.2"
          kubernetes {
              host                   = data.aws_eks_cluster.cluster.endpoint
              cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
              token                  = data.aws_eks_cluster_auth.cluster.token
          }
      }
      provider "null" {
          source = "hashicorp/null"
          version = "~> 3.0.0"
      }
   }
}
