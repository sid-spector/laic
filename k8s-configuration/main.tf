terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.4.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.1"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.0"
    }
  }

  backend "s3" {
    endpoint                    = "fra1.digitaloceanspaces.com"
    key                         = "terraform.tfstate"
    bucket                      = "lab63-infra"
    region                      = "eu-west-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

resource "random_id" "cluster_name" {
  byte_length = 5
}


locals {
  cluster_name = "laic-${random_id.cluster_name.hex}"
}

module "k8s-cluster" {
  source             = "./../k8s-cluster"
  cluster_name  = local.cluster_name
}

data "digitalocean_kubernetes_cluster" "primary" {
  depends_on = [module.k8s-cluster.cluster_name]

  name = module.k8s-cluster.cluster_name
}

resource "local_file" "kubeconfig" {
  depends_on = [module.k8s-cluster.cluster_id]
  count = 1
  content    = data.digitalocean_kubernetes_cluster.primary.kube_config[0].raw_config
  filename   = "${path.root}/kubeconfig"
}

provider "kubernetes" {
  config_path = local_file.kubeconfig[0].filename
}

provider "kubectl" {
   config_path = local_file.kubeconfig[0].filename
   load_config_file       = true
}

provider "helm" {
  kubernetes {
    host  = data.digitalocean_kubernetes_cluster.primary.endpoint
    token = data.digitalocean_kubernetes_cluster.primary.kube_config[0].token
    cluster_ca_certificate = base64decode(
      data.digitalocean_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "helm_release" "argocd" {
  depends_on = [module.k8s-cluster.cluster_id]

  name       = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace = "argocd"
  create_namespace = true

  set {
    name  = "global.networkPolicy.create"
    value = "true"
  }

  set {
    name  = "global.networkPolicy.defaultDenyIngress"
    value = "true"
  }
}

resource "kubernetes_secret" "secret" {
  depends_on = [helm_release.argocd]
 
  metadata {
    annotations = { 
      managed-by = "argocd.argoproj.io"
    }
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
    name = "repo-3538063504"
    namespace = "argocd"
  }

  data = {
    name = "gitops"
    project = "default"
    sshPrivateKey = file(var.ssh_key_path)
    type = "git"
    url = var.repo_url
  }
}

resource "kubectl_manifest" "applicationset" {
  depends_on = [kubernetes_secret.secret, local_file.kubeconfig]

  yaml_body = templatefile("${path.module}/assets/application.yaml",{})
}

resource "kubernetes_namespace" "jitsi_meet"{
  metadata {
    name = "jitsi-meet"
  }
}

resource "kubernetes_config_map" "loadbalancer" {
  depends_on = [module.k8s-cluster.loadbalancer_ip, local_file.kubeconfig, kubernetes_namespace.jitsi_meet]

  metadata {
    name = "loadbalancer"
    namespace = kubernetes_namespace.jitsi_meet.metadata[0].name
  }

  data = {
    loadbalancer_ip = module.k8s-cluster.loadbalancer_ip
  }
}

resource "null_resource" "kubeconfig_guard" {
  depends_on = [local_file.kubeconfig]
  provisioner "local-exec" {
    command = "echo 'Guard to ensure kubeconfig is not destroyed too early'"
  }
}