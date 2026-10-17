---
id: arch-tier-ctid
title: Tier and CTID Scheme
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [architecture, tier, ctid]
retrievable: true
---

# Tier and CTID Scheme

## 1. Numbering

Steps of 10 per tier with gaps for expansion without renumbering. VMs are outside CTID numbering.

| Tier | Name | CTID range | Services in build scope |
|---|---|---|---|
| 10 | Network / Ingress | 110–190 | Pi-hole (110), NPM (120) |
| 20 | Data | 210–290 | Postgres (210), Redis (220), pgAdmin (230) |
| 30 | Identity & Access | 310–390 | Vaultwarden (320) |
| 40 | Application | 410–490 | Karakeep (420) |
| VM | Virtual machines | 100, 101+ | HAOS (100 at `.3`); `.4-.10` reserved for next VMs |

Future reservations live in `../roadmap/future-services.md` — do not allocate them without a build trigger.

## 2. Per-tier notes

- **Karakeep** is a 3-container bundle (app + Meilisearch + browserless) in one LXC — the sanctioned exception to 1-service-1-LXC.
- **Postgres** is a shared instance: one database + one owner role per app, added as list entries. Research each app first — several bundled apps (Karakeep, Vaultwarden) are SQLite-only and must not get a shared DB.
- **Redis** is a shared cache. Nothing in the initial build consumes it; verify app docs support external Redis before wiring.
- **Portainer** (if ever added) manages Docker lifecycles only on Docker LXCs. It cannot manage native LXCs.

## 3. FAQ

**Q: Can I insert a new service without renumbering?**
A: Yes — use the next free multiple of 10 in the tier (e.g. next Tier 40 = 430, then 440).

**Q: Does CTID appear in DNS?**
A: No. DNS is human-memorable (`karakeep.haytham.internal`); CTID is infra bookkeeping.

**Q: Where do future VMs go?**
A: VMID 101+ at `.4` upward, first free. Reserve the router IP before creating the VM.
