provider "google" {
  project = "your_project_id"
  region  = "us-central1"
}

resource "google_compute_network" "vpc_network" {
  name                    = "shiori-network"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance_template" "shiori_instance_template" {
  name        = "shiori-instance-template"
  machine_type = "e2-micro"

  disk {
    auto_delete = true
    boot       = true

    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    git clone https://github.com/RadhiFadlillah/shiori.git
    cd shiori
    go build -o shiori cmd/shiori/main.go
    ./shiori server &
    EOT
}

resource "google_compute_instance_group_manager" "shiori_instance_group_manager" {
  name = "shiori-instance-group-manager"
  base_instance_name = "shiori"
  instance_template = google_compute_instance_template.shiori_instance_template.self_link
  target_size = 2
}

resource "google_compute_http_health_check" "shiori_health_check" {
  name               = "shiori-health-check"
  check_interval_sec = 10
  timeout_sec        = 5
  unhealthy_threshold = 2
  healthy_threshold   = 2

  http_health_check {
    request_path = "/"
  }
}

resource "google_compute_backend_service" "shiori_backend_service" {
  name        = "shiori-backend-service"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group_manager.shiori_instance_group_manager.self_link
  }

  health_checks = [google_compute_http_health_check.shiori_health_check.self_link]
}

resource "google_compute_url_map" "shiori_url_map" {
  name        = "shiori-url-map"
  default_service = google_compute_backend_service.shiori_backend_service.self_link

  host_rule {
    hosts = ["shiori.example.com"]
  }

  path_matcher {
    name = "shiori-path-matcher"
    default_service = google_compute_backend_service.shiori_backend_service.self_link

    path_rule {
      paths = ["/"]
      service = google_compute_backend_service.shiori_backend_service.self_link
    }
  }
}

resource "google_compute_global_forwarding_rule" "shiori_forwarding_rule" {
  name        = "shiori-forwarding-rule"
  target      = google_compute_url_map.shiori_url_map.self_link
  port_range  = "80"
  ip_address  = "0.0.0.0"
}
