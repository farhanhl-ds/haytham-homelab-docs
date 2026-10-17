---
id: svc-karakeep-420
title: Karakeep — Tier 40 App (CTID 420)
tier: "40"
ctid: "420"
ip: 192.168.100.42
status: planned
last_verified: unreleased
tags: [karakeep, bookmarks, tier40, docker, meilisearch]
retrievable: true
---

# Karakeep — Tier 40 App (CTID 420)

## 1. Purpose

Bookmark manager. Full chain proves DNS → proxy → SSL → app → search → screenshot.

## 2. Spec

| Field | Value |
|---|---|
| CTID / IP | 420 / `192.168.100.42` |
| Resources | 2 cores / 4 GB RAM (headless Chrome is RAM-hungry; lower values OOM on crawl) / 24 GB disk |
| Base | Docker, **3-container bundle in one LXC**: `karakeep:3000` + `meilisearch` (internal `:7700`) + `browserless` (internal websocket) |
| DB | SQLite (upstream is SQLite-only; do not create a shared-Postgres DB for it) |

## 3. Provisioning

- Terraform `module.tier40["karakeep"]`.
- Ansible `roles/karakeep` (+ `docker` dependency), pinned to a known upstream version (check release notes before bumping). Env: `NEXTAUTH_URL=https://karakeep.haytham.internal`, `DATA_DIR=/data`, `MEILI_ADDR=http://meilisearch:7700`, `BROWSER_WEBSOCKET_URL` to browserless, `MEILI_NO_ANALYTICS=true` on Meilisearch.

## 4. Configuration

- Secrets (all inter-container, not user creds): `vault_karakeep_nextauth_secret`, `vault_karakeep_meili_master_key`, `vault_karakeep_browser_token` (each 32-char alphanumeric from `openssl rand -base64 32 | tr -dc A-Za-z0-9 | head -c 32`).
- Permission pre-check (pgAdmin pattern): Karakeep app runs as **root** — safe to bind-mount without UID fix. For `meili_data`, if `Permission denied` appears, apply the pgAdmin `chown` pattern with the image UID.
- User auth: self-registration in web UI on first run (no default, no preseed).
- NPM: `karakeep.haytham.internal → 192.168.100.42:3000`, wildcard cert.

## 5. Verification

```bash
ssh root@192.168.100.42 "docker ps"
# Expect: 3 Up, karakeep healthy
```

Browser E2E: save bookmark → thumbnail appears (browserless OK) → search finds it (Meilisearch OK).

## 6. Data note

Bookmarks in SQLite `/data` — ephemeral. Rebuild = manual re-entry until export automation exists (see persistence-design).

## 7. FAQ

**Q: Why isn't Karakeep on shared Postgres?**
A: Upstream is SQLite-only.

**Q: How do I add the next Tier 40 app?**
A: Next free CTID, new `locals.tf` entry, new role reusing `docker`, new NPM Proxy Host. Research DB support first.
