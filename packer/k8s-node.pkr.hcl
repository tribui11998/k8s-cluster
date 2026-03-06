packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1.1"
    }
  }
}

variable "project_id" {
  type = string
}

variable "zone" {
  type    = string
  default = "asia-southeast1-a"
}

variable "k8s_version" {
  type    = string
  default = "1.35"
}

locals {
  timestamp  = formatdate("YYYYMMDDhhmmss", timestamp())
  image_name = "k8s-node-${local.timestamp}"
}

source "googlecompute" "k8s-node" {
  project_id              = var.project_id
  zone                    = var.zone
  machine_type            = "e2-standard-2"
  source_image_family     = "ubuntu-2404-lts-amd64"
  source_image_project_id = ["ubuntu-os-cloud"]
  image_name              = local.image_name
  image_family            = "k8s-node"
  image_description       = "K8s node image"
  disk_size               = 50
  disk_type               = "pd-ssd"
  ssh_username            = "packer"
  ssh_timeout             = "10m"
  tags                    = ["packer-build"]

  image_labels = {
    build_date  = local.timestamp
    k8s_version = replace(var.k8s_version, ".", "-")
    managed_by  = "packer"
  }
}

build {
  sources = ["source.googlecompute.k8s-node"]

  provisioner "shell" {
    inline = ["cloud-init status --wait"]
  }

  provisioner "shell" {
    script = "scripts/setup-k8s-node.sh"
    environment_vars = [
      "K8S_VERSION=${var.k8s_version}"
    ]
  }

  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }

  post-processor "manifest" {
    output     = "build-manifest.json"
    strip_path = true
  }
}
