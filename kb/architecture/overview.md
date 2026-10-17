---
id: arch-overview
title: Architecture Overview
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [architecture, overview, proxmox]
retrievable: true
---

# Architecture Overview

## 1. Host

- Name `haytham`, single-node Proxmox VE.
- Hardware: Lenovo ThinkCentre M910q Tiny, no dGPU, Intel iGPU only (reserved for future media transcoding).
- Network: `vmbr0`, subnet `192.168.100.0/24`, gateway `192.168.100.1`. Host at `.2`, set at install time (see `ip-addressing.md`).

## 2. Layering principle

```
Terraform (bpg/proxmox)          Ansible (WSL control node)
───────────────────────   →      ─────────────────────────
LXC shell, CPU/RAM/disk         Package install, app config
Network + static IP, hostname   Systemd units, compose files
Cloud-init user + SSH key       App users/permissions
```

Terraform stops when each container exists, has the correct IP, and is SSH-reachable. Everything after is Ansible (one role per app, idempotent). See `terraform-strategy.md` and `ansible-strategy.md`.

## 3. Tier map

Full table in `tier-and-ctid-scheme.md`. Summary:

| Tier | Name | Scope |
|---|---|---|
| 10 | Network/Ingress (Pi-hole 110, NPM 120) | Build first |
| 20 | Data (Postgres 210, Redis 220, pgAdmin 230) | Shared layer, no app coupling required |
| 30 | Identity (Vaultwarden 320) | Single service |
| 40 | Application (Karakeep 420) | Leaf consumer |
| VM 100 | HAOS (manual, not Terraform) | Parallel track |

Default: **1 service = 1 LXC**, except apps distributed as multi-container bundles (Karakeep: app + search + browser) which stay self-contained in one LXC.

Future tiers (50 AI/ML, 60 Media, 70 CI/CD, 80 Backup, 90 Observability) are reserved and documented in `../roadmap/future-services.md`.

## 4. Cross-cutting decisions

- DNS base `haytham.internal` — see `dns-naming.md`.
- Wildcard self-signed SSL — see `ssl-strategy.md`.
- Static IPs in Terraform, DHCP reservation only for VMs — see `ip-addressing.md`.
- No TrueNAS on current hardware; Paperless-ngx skipped — see `../decisions/ADR-003-no-truenas-paperless.md`.
- No direct community-scripts provisioning — see `../decisions/ADR-001-no-community-scripts.md`.

## 5. FAQ

**Q: Where do I start as a new operator?**
A: Read this file, then `tier-and-ctid-scheme.md`, `../reference/ip-ctid-matrix.md`, then `../roadmap/build-sequence.md`.
