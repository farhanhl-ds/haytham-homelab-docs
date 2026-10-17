---
id: svc-pihole-110
title: Pi-hole — Tier 10 Network (CTID 110)
tier: "10"
ctid: "110"
ip: 192.168.100.11
status: planned
last_verified: unreleased
tags: [pihole, dns, tier10, network]
retrievable: true
---

# Pi-hole — Tier 10 Network (CTID 110)

## 1. Purpose

LAN DNS + adblock and authoritative resolver for `*.haytham.internal` (wildcard to NPM). Must be up before any `*.haytham.internal` URL works.

## 2. Spec

| Field | Value |
|---|---|
| CTID / IP | 110 / `192.168.100.11` (see `../reference/ip-ctid-matrix.md`) |
| Resources | 1 core / 512 MB / 4 GB (`apt` + Pi-hole FTL OOM-killed at 128 MB on Ubuntu 24.04 — 512 MB is the floor) |
| Base | Ubuntu 24.04 LXC, native install (not Docker) |
| Upstream | `https://install.pi-hole.net` (official unattended installer) |

## 3. Provisioning

- Terraform: `module.tier10["pihole"]` (`for_each` over `tier10_containers`), `nesting=true`.
- Ansible: `tier10.yml` → `roles/pihole`. Idempotent via `/etc/pihole/setupVars.conf` existence check.

## 4. Configuration

Anticipate these Pi-hole v6 requirements in the role (do not treat as post-install fixes):

- `setupVars.conf` (templated): `PIHOLE_INTERFACE`, `IPV4_ADDRESS=<host>/24`, upstreams `1.1.1.1,1.0.0.1`, `QUERY_LOGGING=true`, web stack enabled, `WEBPASSWORD=<vault_pihole_webpassword>`.
- Password: `pihole setpassword` (v6 command). The v5 `pihole -a -p` exits 0 but does not authenticate (auth moved to `pihole.toml`).
- Gravity: `pihole -g` with retries. Unattended installs sometimes skip gravity; symptom is "Domains on Lists: Error (-2)".
- Wildcard template `wildcard-haytham.conf.j2` → `/etc/dnsmasq.d/99-wildcard-haytham.conf`:
  ```
  server=/haytham.internal/#
  address=/.haytham.internal/192.168.100.12
  ```
- Enable `pihole-FTL --config misc.etc_dnsmasq_d true` + restart handler (v6 ignores that directory by default). The web UI Local DNS page cannot create wildcards.

## 5. Verification

```bash
dig karakeep.haytham.internal @192.168.100.11 +short
# Expect: 192.168.100.12

dig karakeep.haytham.internal @192.168.100.11
# Expect ANSWER SECTION: karakeep.haytham.internal. 0 IN A 192.168.100.12
```

Dashboard shows tens of thousands of gravity domains (count varies by list version; zero/error = run `pihole -g`).

## 6. Known gotchas

- Query `dig @<pihole-ip>` directly; OS default resolver tests are invalid until the OS points at Pi-hole.
- Internal domains fail but internet works = DNS order problem. See `../operations/dns-workstation-swap.md`.

## 7. FAQ

**Q: What is Pi-hole's IP and URL?**
A: `192.168.100.11`, `https://pihole.haytham.internal` (via NPM, redirects `/` → `/admin`).

**Q: SSH warns "host identification changed" after rebuild?**
A: Expected — new OS = new host keys. `ssh-keygen -f ~/.ssh/known_hosts -R '192.168.100.11'`.
