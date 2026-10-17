locals {
  # ============================================
  # Base config
  # ============================================
  domain      = "haytham.internal"
  target_node = "haytham" # node name as shown in Datacenter -> haytham in the Proxmox UI

  network = {
    bridge  = "vmbr0"
    gateway = "192.168.100.1"
    cidr    = 24 # /24, same as subnet mask 255.255.255.0
  }

  # ============================================
  # Tier & CTID scheme
  # ------------------------------------------------------------------
  # 10 = Network / Ingress            70 = (reserved) CI/CD & Automation
  # 20 = Data / Persistence           80 = (reserved) Backup & DR
  # 30 = Identity & Access Mgmt       90 = Observability & Monitoring
  # 40 = Application Services
  # 50 = AI / ML Services
  # 60 = Media Services
  #
  # IP formula   : last_octet = CTID / 10
  # Static range : 192.168.100.2  - 192.168.100.99
  # DHCP pool    : 192.168.100.100 - 192.168.100.254
  # Companion block (used when CTID/10 is not a round number, e.g. CTID x11-x19):
  #                192.168.100.180 - 192.168.100.199 (recorded manually per case)
  # ============================================

  # Containers in scope (Phase 1 target was Karakeep up and running; Tier 30 added in Phase 2)
  containers = {
    pihole = {
      tier     = 10
      ctid     = 110
      hostname = "pihole"
      ip       = "192.168.100.11"
      cores    = 1
      memory   = 512
      disk_gb  = 4
      tags     = ["tier-network", "dns"]
    }
    npm = {
      tier     = 10
      ctid     = 120
      hostname = "npm"
      ip       = "192.168.100.12"
      cores    = 1
      memory   = 384
      disk_gb  = 8
      tags     = ["tier-network", "reverse-proxy"]
    }
    postgres = {
      tier     = 20
      ctid     = 210
      hostname = "postgres"
      ip       = "192.168.100.21"
      cores    = 1
      memory   = 512
      disk_gb  = 16
      tags     = ["tier-data", "database"]
    }
    redis = {
      tier     = 20
      ctid     = 220
      hostname = "redis"
      ip       = "192.168.100.22"
      cores    = 1
      memory   = 256
      disk_gb  = 4
      tags     = ["tier-data", "cache"]
    }
    pgadmin = {
      tier     = 20
      ctid     = 230
      hostname = "pgadmin"
      ip       = "192.168.100.23"
      cores    = 1
      memory   = 512
      disk_gb  = 8
      tags     = ["tier-data", "admin-tool"]
    }
    karakeep = {
      tier     = 40
      ctid     = 420
      hostname = "karakeep"
      ip       = "192.168.100.42"
      cores    = 2
      memory   = 4096
      disk_gb  = 24
      tags     = ["tier-app", "bookmarks"]
    }
    vaultwarden = {
      tier     = 30
      ctid     = 320
      hostname = "vaultwarden"
      ip       = "192.168.100.32"
      cores    = 1
      memory   = 256
      disk_gb  = 8
      tags     = ["tier-identity", "password-manager"]
    }
    # NOTE: Infisical (330) deferred — see kb/decisions/ADR-006-infisical-deferred.md.
    # To revive: re-add the container block here (CTID 330, 192.168.100.33).
  }

  # Per-tier subsets, used for for_each in the root module calls
  tier10_containers = { for k, v in local.containers : k => v if v.tier == 10 }
  tier20_containers = { for k, v in local.containers : k => v if v.tier == 20 }
  tier30_containers = { for k, v in local.containers : k => v if v.tier == 30 }
  tier40_containers = { for k, v in local.containers : k => v if v.tier == 40 }
}
