# main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "user-cifrgcupmaah"
  region  = "asia-southeast1"
  zone    = "asia-southeast1-a"
}

# Network
resource "google_compute_network" "vpc" {
  name                    = "my-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "asia-southeast1"
  network       = google_compute_network.vpc.id
}

# Firewall - cho phép SSH
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Nên giới hạn IP cụ thể
}

# VM Instance
resource "google_compute_instance" "vm" {
  name         = "my-vm"
  machine_type = "e2-medium"  # 2 vCPU, 4GB RAM
  zone         = "asia-southeast1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 20  # GB
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    # Gán public IP
    access_config {}
  }

  metadata = {
    #ssh-keys = "username:${file("~/.ssh/id_rsa.pub")}"
  }

  tags = ["ssh-server"]

  labels = {
    environment = "dev"
  }
}

# Output
output "vm_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}