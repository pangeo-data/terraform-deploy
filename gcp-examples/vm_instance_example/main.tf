provider "google" {
  credentials = var.credential-file
  project     = var.project
  region      = var.region
  zone        = var.zone
  version     = "~>v3.39.0"
}
