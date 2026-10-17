---
id: roadmap-future-services
title: Roadmap — Future Services (reserved, not built)
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [roadmap, future, reserved]
retrievable: true
---

# Roadmap — Future Services (reserved, not built)

> Everything here is reserved capacity with a build trigger. Do not provision without meeting the trigger. CTIDs/IPs are reservations, not deployments.

## Hygiene backlog (after green build)

- [ ] Consolidate to one SSH keypair.
- [ ] Cert + vault password → Vaultwarden attachments; remove loose copies.
- [ ] Vaultwarden restore drill (P0 — lockout risk).
- [ ] Router Primary DNS → `.11`; decide Secondary policy (strict vs public fallback).
- [ ] Public domain + split-horizon + DNS-01 LE (replaces per-device CA trust).

## Reserved services

| CTID | IP | Service | Trigger / constraint |
|---|---|---|---|
| 310 | .31 | SSO (Authelia default, Authentik if multi-app) | Concrete OIDC requirement (see ADR-004) |
| 330 | .33 | Machine secrets manager | Consumers beyond Ansible Vault / rotation pain. Revival: `locals.tf` block → `apply` → inventory + `tier30.yml` + `group_vars` pairs (generate once, encrypt twice) → role from spec → NPM host |
| 410 | .41 | Outline | Needs shared-Postgres entry + research first |
| 440 | .44 | Homepage (root `haytham.internal`) | After NPM stable |
| 430 | .43 | Postiz | Heavy (PG + Redis + Temporal + app); prefer native scheduling unless need is concrete |
| 450 | — | Paperless-ngx | Skipped, reserved (see ADR-003) |
| 510 | .51 | Ollama | Split LXC from OpenWebUI (independent restarts) |
| 520 | .52 | OpenWebUI | Split LXC from Ollama |
| 610 | .61 | Immich | Self-contained bundle (own Postgres + pgvecto + Redis); do not use shared Tier 20; needs `/dev/dri` bind-mount for Quick Sync |
| 910 | .91 | Uptime Kuma | Observability need |
| 920 | .92 | Portainer | Optional; manages Docker LXCs only |
| 101+ | .4-.10 | Next VMs | First free IP. Example: VM101 devbox at `.4` |

## Research rule before any new app (applies to all rows above)

For each candidate confirm: DB support (shared PG vs SQLite vs bundled), image user (root vs UID — pgAdmin 5050 lesson), ports, official compose vs native install.

## FAQ

**Q: What is the single most urgent future item?**
A: Vaultwarden backup drill — credential-store loss is lockout, not inconvenience.
