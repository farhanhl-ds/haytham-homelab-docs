---
id: arch-dns-naming
title: DNS and Naming Convention
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [architecture, dns, pihole]
retrievable: true
---

# DNS and Naming Convention

## 1. Base domain

`haytham.internal` — flat, single-level, no CTID in names:

```
haytham.internal              → Homepage (future root, reserved)
pihole.haytham.internal
npm.haytham.internal
karakeep.haytham.internal
pve.haytham.internal          → Proxmox UI (192.168.100.2)
```

## 2. Why not .local / single-label

- **Not `.local`:** reserved for mDNS/Bonjour (RFC 6762). Operating systems intercept it before it becomes a DNS query — Pi-hole would never answer.
- **Not single-label `haytham`:** no ICANN protection, collision risk with future gTLDs, plus browser/cookie/WebAuthn ambiguity.
- **Why `.internal`:** RFC 9476, ICANN-reserved for private use, never delegable publicly.

## 3. Implementation (Pi-hole)

Single wildcard dnsmasq record `*.haytham.internal → 192.168.100.12` (NPM):

- File `/etc/dnsmasq.d/99-wildcard-haytham.conf` via Ansible template (see `services/network-pihole-110.md`).
- Pi-hole v6 does not load `/etc/dnsmasq.d/` by default — the role must set `pihole-FTL --config misc.etc_dnsmasq_d true` + restart.
- Web UI Local DNS Records cannot do wildcards — the custom config file is the only path.
- Verify with a direct query (bypasses OS default resolver): `dig karakeep.haytham.internal @192.168.100.11` → `192.168.100.12`.

## 4. Client / router policy

- Workstation testing uses manual DNS (`192.168.100.11` first). Router-level Primary DNS change waits until Pi-hole + NPM verify green (blast radius = all home devices). Secondary policy is decided at cutover time.
- DNS order matters: clients stop at the first definitive answer (including NXDOMAIN). See `operations/dns-workstation-swap.md`.

## 5. Container-level DNS (Terraform default)

LXC containers use public resolvers (`dns_servers = ["1.1.1.1", "1.0.0.1"]`). This is intentional:

- Containers must resolve public names (`apt`, Docker Hub) during provisioning, exactly when Pi-hole itself may be down or absent. Pointing containers at Pi-hole creates a circular dependency.
- Nothing inside a container needs `*.haytham.internal`: Ansible reaches hosts by IP, and inter-service traffic uses IPs. Internal names are only needed on operator workstations and LAN clients.

Do not point containers at `192.168.100.11` unless a container genuinely needs internal names at runtime.

## 6. FAQ

**Q: Do I need a DNS record per new service?**
A: No — wildcard covers all `*.haytham.internal`. Just add the NPM Proxy Host.

**Q: Why do internal domains fail when Pi-hole is listed second?**
A: The client queries the public resolver first, gets an authoritative NXDOMAIN, and never asks Pi-hole. See resolver-order note above.
