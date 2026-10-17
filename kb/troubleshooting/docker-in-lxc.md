---
id: ts-docker-in-lxc
title: Docker in Unprivileged LXC — Required Setup
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [troubleshooting, docker, lxc, overlayfs]
retrievable: true
---

# Docker in Unprivileged LXC — Required Setup

## 1. Required configuration (use from the start)

`nesting=1` alone (unprivileged, default `overlayfs`/`overlay2`) is sufficient for Docker on Ubuntu 24.04 LXC. No `keyctl`, no `privileged`, no `vfs`. Applies to NPM, pgAdmin, Vaultwarden, Karakeep, and future Docker bundles.

Declare `nesting=true` in Terraform (not via `pct set` after the fact).

## 2. Do not use

- `keyctl` flag — Proxmox rejects it for non-`root@pam` API users. Not needed.
- `vfs` storage driver — masks the real error and wastes disk. Stay on `overlay2` default.
- Docker downgrades or extra `swap` to chase provisioning errors — same failure mode; look at state first.

## 3. Corrupt-state recovery

If a Docker LXC reports misleading `no space left` with free disk/inodes, or fails after driver swaps and forced restarts, assume `/var/lib/docker` is corrupt (prior-attempt state, not permissions/kernel/version):

```bash
systemctl stop docker
rm /etc/docker/daemon.json   # back to overlay2 default
rm -rf /var/lib/docker       # full wipe
systemctl start docker
# retry compose up → clean result
```

Rule: wipe `/var/lib/docker` clean before concluding a permissions/kernel/version fault.

## 4. FAQ

**Q: Overlay/space error on a new Docker LXC?**
A: Wipe `/var/lib/docker` first, then escalate. Do not jump to privileged/vfs.
