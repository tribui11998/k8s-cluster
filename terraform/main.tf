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

# VM Instance 2
resource "google_compute_instance" "vm2" {
  name         = "my-vm-2"
  machine_type = "e2-custom-4-8192"  # 4 vCPU, 8GB RAM
  zone         = "asia-southeast1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 200  # GB
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

  tags = ["ssh-server", "k8s-worker"]

  labels = {
    environment = "dev"
  }

  allow_stopping_for_update = true
}

# VM Instance 1
resource "google_compute_instance" "vm" {
  name         = "my-vm"
  machine_type = "e2-custom-4-8192"  # 4 vCPU, 8GB RAM
  zone         = "asia-southeast1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 200  # GB
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

  allow_stopping_for_update = true
}


# Output
output "vm_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

resource "google_compute_firewall" "k8s-worker" {
  name    = "allow-k8s-worker"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["10250", "30000-32767"] # kubelet + NodePort range
  }

  source_ranges = ["10.0.1.0/24"]
}

resource "google_compute_firewall" "k8s-master" {
  name    = "allow-k8s-master"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6443", "2379-2380", "10250", "10259", "10257"]
  }

  source_ranges = ["10.0.1.0/24"]  # Chỉ cho phép từ subnet nội bộ
}

resource "google_compute_firewall" "k8s-flannel" {
  name    = "allow-flannel"
  network = google_compute_network.vpc.name

  allow {
    protocol = "udp"
    ports    = ["8472"]
  }

  source_ranges = ["10.0.1.0/24"]
}

resource "google_compute_firewall" "nodeport" {
  name    = "allow-nodeport"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["30080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s-worker"]
}