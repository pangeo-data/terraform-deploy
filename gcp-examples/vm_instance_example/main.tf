provider "google" {
  credentials = file(var.credential_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
  version     = "~>v3.39.0"
}

resource "google_compute_instance" "google-vm" {
  name = var.deployment_name
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
  }
}
