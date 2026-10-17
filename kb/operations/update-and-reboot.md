---
id: ops-update-reboot-all
title: Runbook — System Update and Reboot All LXC
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [operations, update, reboot, maintenance]
retrievable: true
---

# Runbook — System Update and Reboot All LXC

## 1. Purpose

Patch all LXC (`apt upgrade`) and reboot in dependency-safe order without crashing consumers (DBs first, proxy last). Also applies Terraform resource resizes (cgroup limits need reboot).

## 2. When to use / not use

- Use: routine patching, post-`locals.tf` resize, post-maintenance fresh-start.
- Do not use for full builds — see `build-from-scratch.md`. Do not include VM 100 here (`qm`, separate lifecycle).

## 3. Dependency order

Always reboot in depended-upon-first order:

| Order | Tier | CTIDs | Reason |
|---|---|---|---|
| 1 | 20 data-core | 210 220 | everyone depends here |
| 2 | 20 data-admin | 230 | consumer only |
| 3 | 30 identity | 320 | before apps |
| 4 | 40 app | 420 | leaf consumer |
| 5 | 10 network | 110 120 | DNS/proxy last; brief downtime OK |

Update this table + scripts when adding containers. Source CTIDs from `reference/ip-ctid-matrix.md`.

Current sets:

```
DATA_TIER="210 220"  DATA_ADMIN="230"  IDENTITY="320"  APP="420"  NETWORK="110 120"
```

## 4. Pre-update checklist

- [ ] No active writes/jobs (Karakeep crawl, etc.).
- [ ] If `locals.tf` resized: `terraform plan` shows `~` in-place (not `-/+`), `apply` succeeded.
- [ ] Snapshot if risky (major bump, not routine `upgrade`):
  ```bash
  for ctid in 110 120 210 220 230 320 420; do pct snapshot $ctid "pre-update-$(date +%Y%m%d)"; done
  ```

## 5. Update (all, then reboot all — not interleaved)

```bash
for ctid in 110 120 210 220 230 320 420; do
  echo "=== Updating CT $ctid ==="
  pct exec $ctid -- bash -c "apt update && apt upgrade -y"
done
```

## 6. Reboot (dependency-safe)

Save as `reboot-all-lxc.sh` on node `haytham`, `chmod +x`:

```bash
#!/bin/bash
set -e
reboot_group() {
  local label="$1"; shift
  for ctid in "$@"; do
    echo ">> Rebooting CT $ctid ($label)..."
    pct reboot $ctid
    sleep 8
  done
  echo ">> Waiting extra 10s for $label to stabilize..."
  sleep 10
}
reboot_group "data-core"  210 220
reboot_group "data-admin" 230
reboot_group "identity"   320
reboot_group "app"        420
reboot_group "network"    110 120
echo "All containers rebooted in dependency-safe order."
```

`pct reboot` suffices for new cgroup limits; no manual shutdown/start needed.

## 7. Post-reboot verification

```bash
for ctid in 110 120 210 220 230 320 420; do pct status $ctid; done
# Expect all: status: running
for ctid in 110 120 210 220 230 320 420; do echo "=== CT $ctid ==="; pct config $ctid | grep -E "^(memory|cores):"; done
# Cross-check vs locals.tf after resize
```

- [ ] All running, resources match.
- [ ] Smoke: `curl -I http://192.168.100.12`, open Karakeep/Vaultwarden/pgAdmin once.
- [ ] Suspicious logs: `pct exec <ctid> -- journalctl -p err -b`.

## 8. Rollback

```bash
pct rollback <ctid> pre-update-YYYYMMDD
# or for bad resize:
git checkout HEAD~1 -- locals.tf
terraform apply
pct reboot <ctid>
```

## 9. FAQ

**Q: Can I update+reboot one-by-one?**
A: Avoid — creates long per-service windows. Update all, then reboot in order.

**Q: Reboot data tier last to keep DNS up?**
A: No — consumers fail DB connects while DNS stays up. Data first is mandatory.
