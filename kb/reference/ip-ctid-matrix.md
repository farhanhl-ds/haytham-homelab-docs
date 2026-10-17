---
id: ref-ip-ctid-matrix
title: IP and CTID Matrix (canonical)
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [reference, ip, ctid, network]
retrievable: true
---

# IP and CTID Matrix (canonical)

> The only source of truth for VMID/CTID ↔ IP ↔ hostname. All other pages link here.

## Scheme

- Subnet `192.168.100.0/24`, gateway `192.168.100.1`.
- Formula for LXC: `last_octet = CTID / 10`.
- `.1` gateway. `.2` Proxmox host. `.3` VM100. `.4-.10` reserved VM block (next VM takes first free). `.11+` LXC via formula. `.100-.254` DHCP pool. `.180-.199` companion block for non-round CTIDs (manual per case).

## Matrix

| CTID/VMID | Service | IP | DNS | Tier |
|---|---|---|---|---|
| — | Proxmox host `haytham` | 192.168.100.2 | `pve.haytham.internal` | host |
| 100 (VM) | Home Assistant OS | 192.168.100.3 (DHCP reservation, MAC-pinned) | — (direct IP `:8123`) | vm |
| 101+ (VM) | Reserved future VMs | 192.168.100.4 - 192.168.100.10 (first free) | — | vm |
| 110 | Pi-hole | 192.168.100.11 | `pihole.haytham.internal` | 10 |
| 120 | NPM | 192.168.100.12 | `npm.haytham.internal` | 10 |
| 210 | Postgres | 192.168.100.21 | — (non-HTTP) | 20 |
| 220 | Redis | 192.168.100.22 | — (non-HTTP) | 20 |
| 230 | pgAdmin | 192.168.100.23 | `pgadmin.haytham.internal` | 20 |
| 320 | Vaultwarden | 192.168.100.32 | `vaultwarden.haytham.internal` | 30 |
| 420 | Karakeep | 192.168.100.42 | `karakeep.haytham.internal` | 40 |

Reserved (see `roadmap/future-services.md`): 310 SSO `.31`, 330 secrets-manager `.33`, 410 Outline `.41`, 430 Postiz `.43`, 440 Homepage `.44` (root `haytham.internal`), 450 Paperless-ngx (skipped, reserved), 510 Ollama `.51`, 520 OpenWebUI `.52`, 610 Immich `.61`, 910 Uptime Kuma `.91`, 920 Portainer `.92` (optional).

## FAQ

**Q: What IP is service X?**
A: Look it up above. For LXC, divide its CTID by 10.

**Q: Why is HAOS on .3?**
A: VMs sit outside the LXC formula. `.2` is the host, `.3` is the first VM slot. Later VMs take `.4`, `.5`, and so on.

**Q: Why DHCP reservation for VMs but static IP for LXC?**
A: LXC static IPs are declared in Terraform. VMs are managed manually via `qm`; a router-side reservation pinned to the VM MAC survives OS resets and recreates.
