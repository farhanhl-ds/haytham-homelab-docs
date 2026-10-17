---
id: svc-pgadmin-230
title: pgAdmin — Tier 20 Admin (CTID 230)
tier: "20"
ctid: "230"
ip: 192.168.100.23
status: planned
last_verified: unreleased
tags: [pgadmin, postgres, tier20, docker]
retrievable: true
---

# pgAdmin — Tier 20 Admin (CTID 230)

## 1. Purpose

Web UI for Postgres administration. Consumer of Tier 20, dependency of nobody.

## 2. Spec

| Field | Value |
|---|---|
| CTID / IP | 230 / `192.168.100.23` |
| Resources | 1 core / 512 MB / 8 GB |
| Base | Docker via `roles/docker` dependency, compose `80:80`, preseed `PGADMIN_DEFAULT_EMAIL/PASSWORD` |

## 3. Provisioning

- Terraform: add entry to `locals.tf` only (no `containers.tf` change — `for_each` benefit).
- Ansible `roles/pgadmin` + `docker` dependency, `docker-compose.yml.j2`.

## 4. Configuration

- **UID 5050 (mandatory for this non-root image):** pgAdmin runs as UID 5050 inside the image. Host bind-mount `./data` defaults to root ownership → crash-loop `Permission denied: '/var/lib/pgadmin/sessions'`. The role sets `owner=5050 group=5050` before compose up. Generalize: always check the image user before bind-mounting.
- Preseed login `admin@haytham.internal` + `vault_pgadmin_default_password` works on first run (unlike NPM).
- **Rotation constraint:** `PGADMIN_DEFAULT_*` applies on first run only. Changing the vault value + re-running does not rotate an existing account. Rotate via UI (User Management → Change Password) or wipe `./data` for first-run replay. See `operations/secret-rotation.md`.
- NPM: `pgadmin.haytham.internal → 192.168.100.23:80`, wildcard cert.

## 5. Verification

```bash
ssh root@192.168.100.23 "docker ps"
# Expect: pgadmin Up
```

Browser: login, Add Server `192.168.100.21:5432` (user `postgres`) — the server list is stored in pgAdmin data, not env, so re-add it after every rebuild.

## 6. FAQ

**Q: Login fails after vault change + re-run?**
A: Expected (§4). Change via UI or wipe data.

**Q: Container crash-loops with sessions permission denied?**
A: `chown 5050:5050` the data dir, recreate.
