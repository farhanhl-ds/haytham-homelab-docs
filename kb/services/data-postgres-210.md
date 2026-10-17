---
id: svc-postgres-210
title: Postgres — Tier 20 Data (CTID 210)
tier: "20"
ctid: "210"
ip: 192.168.100.21
status: planned
last_verified: unreleased
tags: [postgres, database, tier20, data]
retrievable: true
---

# Postgres — Tier 20 Data (CTID 210)

## 1. Purpose

Shared relational store. Principle: **1 database + 1 owner role per app**, listed in `postgres_databases` (`group_vars/tier20.yml`). New app = new list entry, not new container. Research each app first — SQLite-only or bundled-Postgres apps must not get a shared DB.

## 2. Spec

| Field | Value |
|---|---|
| CTID / IP | 210 / `192.168.100.21` |
| Resources | 1 core / 512 MB / 16 GB |
| Base | Ubuntu 24.04 native apt Postgres |
| Clients | `psql` via `postgresql-client` (WSL tooling) |

## 3. Provisioning

- Terraform `module.tier20["postgres"]`.
- Ansible `roles/postgres` with `community.postgresql`: auto-detect config dir via `find`, `listen_addresses='*'`, `pg_hba` `192.168.100.0/24 scram-sha-256`.

## 4. Configuration

- **Encoding (mandatory):** `encoding=UTF8`, `lc_collate/lc_ctype=C.UTF-8`, `template=template0`. The Ubuntu default inherits `SQL_ASCII`/`C` from `template1` — silent non-ASCII corruption risk if skipped.
- **PG15+ schema grant (mandatory for every app DB):** upstream revoked default `CREATE` on schema `public`. Even DB owners cannot create tables without an explicit grant. The role grants `CREATE,USAGE` on `public` to every `item.owner` in the same loop as user provisioning.
- Initial build ships with `postgres_databases: []` (no consumers — Karakeep and Vaultwarden are SQLite-only by design). Add entries only for apps with documented external-Postgres support.

## 5. Verification

```bash
psql -h 192.168.100.21 -U postgres -c "SELECT 1;"
# Expect: 1 row

psql -h 192.168.100.21 -U postgres -c "SHOW server_encoding;"
```

pgAdmin tree (`https://pgadmin.haytham.internal`) lists expected DBs with UTF8.

## 6. Known gotchas

- `permission denied for schema public` on a fresh app DB = missing privs grant, not wrong password. Fix in `roles/postgres`, not the app role.

## 7. FAQ

**Q: How do I add a database for a new app?**
A: Append to `postgres_databases` in `tier20.yml`, re-run `tier20.yml`. The privs grant applies automatically.

**Q: Does Karakeep/Vaultwarden use this?**
A: No — Karakeep (SQLite-only), Vaultwarden (SQLite). Shared Postgres has no consumers in the initial build by design.
