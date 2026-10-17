---
id: svc-redis-220
title: Redis — Tier 20 Data (CTID 220)
tier: "20"
ctid: "220"
ip: 192.168.100.22
status: planned
last_verified: unreleased
tags: [redis, cache, tier20, data]
retrievable: true
---

# Redis — Tier 20 Data (CTID 220)

## 1. Purpose

Shared cache/queue for apps with documented bring-your-own Redis support. No consumers in the initial build by design — verify app docs before wiring.

## 2. Spec

| Field | Value |
|---|---|
| CTID / IP | 220 / `192.168.100.22` |
| Resources | 1 core / 256 MB / 4 GB (raised from 128 MB: same `apt` OOM class as Pi-hole — the package cache update needs headroom even though `redis-server` steady-state is small) |
| Base | Ubuntu 24.04 native `redis-server` |

## 3. Provisioning

- Terraform `module.tier20["redis"]`.
- Ansible `roles/redis`: `bind 0.0.0.0`, `requirepass=<vault_redis_password>`, `protected-mode no` (gated by LAN-only use; acceptable for homelab).

## 4. Configuration

- Secret: `vault_redis_password` (tier20 scope). If a future app in another tier consumes Redis, its app-side copy must have **identical plaintext** (generate once, encrypt twice under a tier-scoped name).
- LAN-only: bound to `192.168.100.0/24` + `requirepass`. Do not expose beyond the LAN.

## 5. Verification

```bash
redis-cli -h 192.168.100.22 -a '<password>' ping
# Expect: PONG
```

## 6. FAQ

**Q: Does Karakeep/Vaultwarden use shared Redis?**
A: No. Verify external-Redis support in app docs before assuming.

**Q: Is 0.0.0.0 unsafe?**
A: Bound to LAN + `requirepass` + subnet-gated. Do not expose beyond `192.168.100.0/24`.
