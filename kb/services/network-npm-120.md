---
id: svc-npm-120
title: NPM — Tier 10 Ingress (CTID 120)
tier: "10"
ctid: "120"
ip: 192.168.100.12
status: planned
last_verified: unreleased
tags: [npm, reverse-proxy, ssl, tier10, docker]
retrievable: true
---

# NPM — Tier 10 Ingress (CTID 120)

## 1. Purpose

Reverse proxy + SSL termination for every HTTP service. Sole target of the Pi-hole wildcard. No service is directly exposed; all `*.haytham.internal` resolve here.

## 2. Spec

| Field | Value |
|---|---|
| CTID / IP | 120 / `192.168.100.12` |
| Resources | 1 core / 384 MB / 8 GB |
| Base | Ubuntu 24.04 LXC + Docker (via reusable `roles/docker`), `nesting=true`, unprivileged, `overlayfs` default |
| Image | `jc21/nginx-proxy-manager` via compose |

No `keyctl`, no `privileged`, no `vfs` — `nesting=true` with overlayfs is sufficient. See `../troubleshooting/docker-in-lxc.md`.

## 3. Provisioning

- Terraform `module.tier10["npm"]`.
- Ansible `roles/npm` (depends on `roles/docker`), compose via `community.docker.docker_compose_v2`.

## 4. Configuration

NPM stores everything in **SQLite inside the container** — destroyed with the LXC. After every build (see `../operations/build-from-scratch.md`):

1. Create admin account (first-run form, no default creds).
2. Import Custom Certificate `haytham-internal` (key+crt from `~/homelab-cert/`).
3. Proxy Hosts (all: cert `haytham-internal`, Force SSL + HTTP/2):

| Domain | Forward |
|---|---|
| `pihole.haytham.internal` | 192.168.100.11:80 (+ custom location `/` → `rewrite ^/$ /admin permanent;`) |
| `npm.haytham.internal` | 192.168.100.12:81 |
| `pgadmin.haytham.internal` | 192.168.100.23:80 |
| `vaultwarden.haytham.internal` | 192.168.100.32:80 (+ Websockets Support ON) |
| `karakeep.haytham.internal` | 192.168.100.42:3000 |

Pattern for every future HTTP service: add Proxy Host, reuse wildcard cert, no DNS change needed.

## 5. Verification

```bash
ssh root@192.168.100.12 "docker ps"
# Expect: npm Up (stable, not restarting)
# docker info Storage Driver: overlayfs (not vfs)

curl -kI https://pihole.haytham.internal
# Expect: HTTP 301/200 via NPM (trusted without -k once CA is installed)
```

Browser (DNS → Pi-hole): `https://pihole.haytham.internal` → `/admin`, green lock.

## 6. Known gotchas

- Pi-hole v6 root `/` returns 403 by design — the custom location rewrite fixes it.
- Overlay/`no space left` errors after driver swaps = corrupt `/var/lib/docker`, not permissions. Wipe path is in troubleshooting.

## 7. FAQ

**Q: Do I need a DNS record for a new app?**
A: No. Wildcard already points at NPM. Only add the Proxy Host.

**Q: Why did all Proxy Hosts disappear after rebuild?**
A: By design (SQLite in rootfs). Recreate per §4. Durability is tracked in `../architecture/persistence-design.md`.

**Q: Which services don't need NPM?**
A: Non-HTTP (Postgres, Redis). Everything HTTP does.
