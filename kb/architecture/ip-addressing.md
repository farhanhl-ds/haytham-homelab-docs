---
id: arch-ip-addressing
title: IP Addressing Scheme
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [architecture, network, ip]
retrievable: true
---

# IP Addressing Scheme

## 1. Scheme

- Subnet `192.168.100.0/24`, gateway `192.168.100.1`.
- Formula for LXC: `last_octet = CTID / 10`.
- Rationale: CTIDs span 100–990, exceeding one octet. Dividing by 10 is the linear scaling that fits the full range into `.0–.255`.

## 2. Block allocation

Set the Proxmox host to `.2` at ISO install time, before provisioning anything else.

```
.1        Gateway (router)
.2        Proxmox host haytham
.3        VM100 HAOS (DHCP reservation, MAC-pinned)
.4-.10    Reserved VM block (next VM takes first free: .4, then .5, ...)
.11+      LXC via CTID/10
.100-.254 DHCP pool (general devices)
.180-.199 Companion block for non-round CTIDs (x11-x19), manual per case
```

Prerequisites before `terraform apply`:

- Router DHCP pool starts at `.100` (shrink from default `.2` start to avoid colliding with static infrastructure).
- Router has a DHCP reservation: VM100 MAC `BC:24:11:D7:75:C0` → `192.168.100.3`.
- Router DNS stays at ISP default until Pi-hole + NPM are verified; the cutover is a deliberate later step (see `dns-naming.md`).

## 3. Canonical table

See `../reference/ip-ctid-matrix.md` — do not duplicate IPs here.

## 4. FAQ

**Q: Why not use CTID directly as last octet?**
A: Tier 30+ CTIDs exceed 255. The formula is mandatory.

**Q: Static IP or DHCP reservation for LXC?**
A: Static in Terraform for all LXC. Only VMs use DHCP reservations (pinned MAC).
