output "cluster_id" {
  value = digitalocean_kubernetes_cluster.primary.id
}

output "cluster_name" {
  value = digitalocean_kubernetes_cluster.primary.name
}

output "loadbalancer_ip" {
  value = digitalocean_loadbalancer.public.ip
}