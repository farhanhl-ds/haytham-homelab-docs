---
id: arch-persistence-design
title: Persistence Design (ephemeral storage by default)
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [architecture, storage, backup, risk]
retrievable: true
---

# Persistence Design (ephemeral storage by default)

## 1. Default behavior

All data lives **inside LXC rootfs / VM disk** unless a backup or external volume is explicitly built:

- Postgres `/var/lib/postgresql`, Redis dump, pgAdmin `./data`, Karakeep SQLite + `meili_data`, Vaultwarden SQLite, NPM SQLite (Proxy Hosts, certs, admin), HAOS config — all destroyed with `terraform destroy` / `qm destroy`.
- `destroy` is safe for infra testing but **permanent data loss** for production data. Plan exports before any destroy on a loaded system.

## 2. Per-service blast radius

| Service | Data at risk on destroy | Handling |
|---|---|---|
| NPM | All Proxy Hosts, cert import, admin account | Recreate manually per `operations/build-from-scratch.md` |
| pgAdmin | Server connection list (env preseed does not restore it) | Re-add manually: `192.168.100.21:5432` |
| Vaultwarden | Vault items — **lockout risk** if this is the credential store | Export vault to encrypted file before destroy; highest backup priority |
| Karakeep | Bookmarks (SQLite `/data`) | Manual re-entry until export automation exists |
| Postgres/Redis | All databases | No dump automation in initial build |
| HAOS | Automations/integrations/dashboards | No VM backup in initial build |
| SSL cert | Safe — lives in `~/homelab-cert` outside containers | Migrate to Vaultwarden attachment after Tier 30 is up |

## 3. Required practices from day one

- Snapshot before risky updates: `pct snapshot <ctid> pre-update-YYYYMMDD` (see `operations/update-and-reboot.md`). Snapshots are rollback aids, not backups.
- Vaultwarden export drill is P0 — credential-store loss is lockout, not inconvenience.
- Before production use, decide: Proxmox Backup Server (Tier 80 reserved) vs externalized data volumes excluded from container lifecycle vs per-app export automation. Tracked in `roadmap/future-services.md`.

## 4. FAQ

**Q: Can I run build-from-scratch on a loaded system?**
A: Only with manual exports first, or accept total data loss. Read the runbook destroy warning first.

**Q: Why isn't durability in the initial build?**
A: Build order is reproducibility first, durability second. The initial build proves `destroy + rebuild` is clean; backups attach to a known-good layout.
