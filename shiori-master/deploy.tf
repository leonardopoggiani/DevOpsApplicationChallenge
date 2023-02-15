terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "tidy-federation-377908"
  region  = "europe-west3"
}

resource "google_compute_network" "network" {
  name                    = "shiori-network"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "firewall" {
  name    = "shiori-firewall"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "instance" {
  name         = "shiori-instance"
  machine_type = "e2-micro"
  zone = "europe-west1-c"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = google_compute_network.network.self_link
  }

  metadata_startup_script = <<-SCRIPT
    # Install dependencies
    apt-get update
    apt-get install -y curl git

    # Install Go
    curl -sSL https://dl.google.com/go/go1.17.5.linux-amd64.tar.gz | tar -C /usr/local -xz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc

    # Clone the Shiori repository
    git clone https://github.com/go-shiori/shiori.git /opt/shiori

    # Build the Shiori application
    cd /opt/shiori
    go build

    # Start the Shiori application
    ./shiori &
  SCRIPT
}
