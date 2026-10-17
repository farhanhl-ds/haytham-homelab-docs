provider "proxmox" {
  endpoint  = var.pve_endpoint
  api_token = var.pve_api_token

  # Proxmox uses a self-signed cert by default for its own web UI/API
  # (different from the *.haytham.internal wildcard cert we made for NPM).
  # Set false once the API endpoint uses a trusted cert.
  insecure = true

  # bpg/proxmox needs SSH to the node for some operations (snippet upload,
  # certain LXC configs) outside the plain REST API.
  # Make sure SSH key-based auth root@<proxmox-host> works from the machine
  # where you run `terraform apply`.
  ssh {
    agent    = true
    username = "root"
  }
}
