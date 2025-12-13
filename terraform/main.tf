terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Создание firewall правил
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-microservices"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "9000", "9001"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["microservices"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-microservices"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["microservices"]
}

# VM instance
resource "google_compute_instance" "microservices_vm" {
  name         = "microservices-instance"
  machine_type = var.machine_type
  zone         = "${var.region}-a"

  tags = ["microservices"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = var.ssh_public_key != "" ? "${var.ssh_user}:${var.ssh_public_key}" : ""
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common git

    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Start Docker
    systemctl start docker
    systemctl enable docker

    # Create project directory
    mkdir -p /opt/microservices
    chown -R ubuntu:ubuntu /opt/microservices

    echo "Docker and Docker Compose installed successfully" > /var/log/startup-script.log
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Output
output "instance_ip" {
  value       = google_compute_instance.microservices_vm.network_interface[0].access_config[0].nat_ip
  description = "Public IP address of the VM instance"
}

output "instance_name" {
  value       = google_compute_instance.microservices_vm.name
  description = "Name of the VM instance"
}

output "ssh_command" {
  value       = "ssh ubuntu@${google_compute_instance.microservices_vm.network_interface[0].access_config[0].nat_ip}"
  description = "SSH command to connect to the instance"
}
