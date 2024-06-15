terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.4.0"
    }
  }
}


resource "digitalocean_loadbalancer" "public" {
  name   = "loadbalancer-merda"
  region = "${var.region}"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     =  32080
    target_protocol = "http"
  }

  forwarding_rule {
    tls_passthrough = true
    entry_port     = 443
    entry_protocol = "https"

    target_port     =  32443
    target_protocol = "https"
  }

  forwarding_rule {
    entry_port     =  10000
    entry_protocol = "udp"

    target_port     =  32222
    target_protocol = "udp"
  }

  healthcheck {
    port     = 32080
    protocol = "tcp"
  }

  droplet_tag = "porca:madonna"
}


resource "digitalocean_kubernetes_cluster" "primary" {
  name   = "${var.cluster_name}"
  region = "${var.region}"
  # Grab the latest version slug from `doctl kubernetes options versions`
  version = "1.30.1-do.0"

  node_pool {
    tags = ["porca:madonna"]
    name       = "pool-1"
    size       = "s-1vcpu-2gb"
    node_count = 2
  }
}