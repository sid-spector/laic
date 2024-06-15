# variable "cluster_id" {
#   type = string
# }

variable "write_kubeconfig" {
  type        = bool
  default     = false
}

variable "ssh_key_path" {
  type        = string
  default     = "../.id_rsa"
}

variable "repo_url" {
  type        = string
  default     = "##YOUR_GIT_REPO##"
}