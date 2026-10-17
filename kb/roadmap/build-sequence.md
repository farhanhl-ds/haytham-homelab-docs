---
id: roadmap-build-sequence
title: Roadmap — Build Sequence (the only chronology)
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [roadmap, build-order]
retrievable: true
---

# Roadmap — Build Sequence (the only chronology)

> This is the single chronological document in the KB. All other pages are timeless. Build strictly in this order; each step gates the next.

## Phase 1 — Foundation (Proxmox + network)

1. Install Proxmox, host `haytham` at `192.168.100.2`, `vmbr0`, `local` + `local-lvm`.
2. Shrink router DHCP pool to `.100-.254`. Add reservation MAC `BC:24:11:D7:75:C0` → `.3`.
3. Download Ubuntu 24.04 CT template via GUI. Create `terraform@pve!terraform` with the four role grants.
4. Generate wildcard cert (`architecture/ssl-strategy.md`). Keep key/crt/cnf in `~/homelab-cert/` + Windows backup.
5. `terraform apply` — 7 LXC. Workstation DNS in safe mode (public first).

## Phase 2 — Data + identity

6. `ansible-playbook tier10.yml` → verify `dig @192.168.100.11`.
7. `tier20.yml` → verify `psql`, `redis-cli ping`, pgAdmin login.
8. `tier30.yml` → Vaultwarden signup → lock signups → re-run. Migrate cert + vault password to Vaultwarden attachments; remove loose copies.
9. Manual NPM: admin → cert import → 5 Proxy Hosts → pihole rewrite → websockets ON.

## Phase 3 — Apps + VM

10. `tier40.yml` (Karakeep) → E2E `save → thumbnail → search` over `https://karakeep.haytham.internal`.
11. Manual VM100 HAOS (`qm` + GUI attach) → `http://192.168.100.3:8123` → onboarding.
12. Workstation DNS to normal mode (Pi-hole first). Browser sweep of all five HTTPS URLs + HAOS.
13. Acceptance: every playbook `failed=0`, verification block in `operations/build-from-scratch.md` green.

## Phase 4 — Hardening (after green build)

14. Vaultwarden export drill (P0).
15. Decide persistence: PBS (Tier 80) vs external volumes vs per-app exports.
16. Router Primary DNS → `.11` cutover (multi-device need + Secondary policy).
17. Next apps from `future-services.md` in dependency order.

## FAQ

**Q: Can I skip ahead (e.g. Karakeep before Pi-hole)?**
A: No. DNS → proxy → data → identity → app is a dependency chain, not a suggestion.
