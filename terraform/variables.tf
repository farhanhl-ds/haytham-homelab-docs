variable "pve_endpoint" {
  description = "Proxmox VE API URL, e.g.: https://192.168.100.2:8006/"
  type        = string
}

variable "pve_api_token" {
  description = "Format: terraform@pve!terraform=<secret-uuid>"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Absolute path to public key baked into every LXC (file() does not expand ~), e.g.: C:/Users/<you>/.ssh/id_ed25519.pub"
  type        = string
}

variable "ct_root_password" {
  description = "Root password for all containers (fallback access via Proxmox console if SSH fails). Generate with: openssl rand -base64 24"
  type        = string
  sensitive   = true
}
