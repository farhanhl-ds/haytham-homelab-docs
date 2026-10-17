---
id: svc-vaultwarden-320
title: Vaultwarden — Tier 30 Identity (CTID 320)
tier: "30"
ctid: "320"
ip: 192.168.100.32
status: planned
last_verified: unreleased
tags: [vaultwarden, passwords, tier30, docker, identity]
retrievable: true
---

# Vaultwarden — Tier 30 Identity (CTID 320)

## 1. Purpose

Password manager (lightweight Bitwarden-compatible). Designated home for the SSL cert, vault passwords, and any secrets currently in workstation folders.

## 2. Spec

| Field | Value |
|---|---|
| CTID / IP | 320 / `192.168.100.32` |
| Resources | 1 core / 256 MB / 8 GB |
| Base | Docker `vaultwarden/server` |
| DB | SQLite (single-user simplicity; no shared-Postgres dependency by design) |

## 3. Provisioning

- Terraform `module.tier30["vaultwarden"]`.
- Ansible `roles/vaultwarden` (+ `docker` dependency). Secret: `vault_vaultwarden_admin_token` (admin panel = full access).

## 4. Configuration

- `SIGNUPS_ALLOWED=false` after the first account (no open signup for single-user).
- NPM: `vaultwarden.haytham.internal → 192.168.100.32:80`, wildcard cert, **Websockets Support ON** (live sync).
- Flow per build: set signups `true` → create master account → set `false` → re-run playbook. Data is ephemeral, so the account is recreated per rebuild until backups exist.

## 5. Verification

```bash
ssh root@192.168.100.32 "docker ps"
# Expect: vaultwarden Up
```

Browser: `https://vaultwarden.haytham.internal` login + sync test across two devices. Confirm signups are closed.

## 6. Criticality note

Highest backup priority — credential-store loss = lockout from everything else. Export the vault to an encrypted file before any destroy. See `../architecture/persistence-design.md`.

## 7. FAQ

**Q: Why SQLite instead of shared Postgres?**
A: Independence + simplicity for single-user. No multi-user need justifies external DB burden.

**Q: Where does the SSL cert live long-term?**
A: As a Vaultwarden attachment (migrate from `~/homelab-cert` once this service is up).
