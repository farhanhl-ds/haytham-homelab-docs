variable "node_name" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "hostname" {
  type = string
}

variable "description" {
  type    = string
  default = "Managed by Terraform"
}

variable "cores" {
  type    = number
  default = 1
}

variable "memory_mb" {
  type    = number
  default = 512
}

variable "disk_gb" {
  type    = number
  default = 4
}

variable "datastore_id" {
  type    = string
  default = "local-lvm"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "ip_address_cidr" {
  description = "Format: 192.168.100.11/24"
  type        = string
}

variable "gateway" {
  type = string
}

variable "dns_servers" {
  type    = list(string)
  default = ["1.1.1.1", "1.0.0.1"]
}

variable "template_file_id" {
  description = "ID of proxmox_virtual_environment_download_file, or a local:vztmpl/... path"
  type        = string
}

variable "os_type" {
  type    = string
  default = "ubuntu"
}

variable "ssh_public_keys" {
  type = list(string)
}

variable "root_password" {
  type      = string
  sensitive = true
}

variable "unprivileged" {
  type    = bool
  default = true
}

variable "nesting" {
  description = "Set true for all Ubuntu 24.04 containers (systemd 255 needs nesting, not only the ones running Docker). Details: kb/troubleshooting/docker-in-lxc.md"
  type        = bool
  default     = false
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "start_on_boot" {
  type    = bool
  default = true
}