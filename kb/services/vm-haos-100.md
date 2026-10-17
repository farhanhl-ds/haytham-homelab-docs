---
id: svc-haos-100
title: Home Assistant OS — VM 100 (manual)
tier: "vm"
ctid: "100"
ip: 192.168.100.3
status: planned
last_verified: unreleased
tags: [haos, vm, home-assistant, qm]
retrievable: true
---

# Home Assistant OS — VM 100 (manual)

## 1. Purpose

Home automation OS. Full OS image (`qcow2`), not `apt`/`compose` — hence VM (cleaner USB passthrough for future Zigbee/Z-Wave) and **manual `qm` management, not Terraform** (see ADR-005).

## 2. Spec

| Field | Value |
|---|---|
| VMID / IP | 100 / `192.168.100.3` via router DHCP reservation (not static in OS) |
| Resources | 2 cores / 4 GB / imported qcow2 |
| MAC | `BC:24:11:D7:75:C0` — **pinned** so the reservation survives recreates |
| Image | `haos_ova-*.qcow2` in `/var/lib/vz/template/iso` (download once from HAOS GitHub releases, `xz -d`) |

## 3. Canonical create (all flags mandatory)

The BIOS/machine/storage trio + EFI disk are required — defaults produce an unbootable VM (see `../troubleshooting/haos-boot-requirements.md`):

```bash
qm stop 100; qm destroy 100  # only if rebuilding

qm create 100 \
  --name haos \
  --memory 4096 \
  --cores 2 \
  --cpu host \
  --net0 virtio=BC:24:11:D7:75:C0,bridge=vmbr0 \
  --ostype l26 \
  --agent enabled=1 \
  --bios ovmf \
  --machine q35 \
  --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=0 \
  --scsihw virtio-scsi-pci

qm importdisk 100 haos_ova-*.qcow2 local-lvm
# GUI: Hardware → Unused Disk 0 → Edit → Discard → Add
# GUI: Options → Boot Order → scsi0 top, checked, others unchecked
qm start 100
```

Boot takes 2–5 min first time. Console shows `System is ready` with a `ha >` prompt.

## 4. Networking

Router reservation (**DHCP Static IP** menu: MAC → `192.168.100.3`) — centralized, survives OS resets. Do not set static IP inside HAOS. Verify: `qm config 100 | grep net0` MAC matches reservation; `qm status 100` → running.

Access: `http://192.168.100.3:8123` (no NPM Proxy Host). Onboarding wizard creates admin/location on first boot.

## 5. Verification

```bash
qm status 100
# Expect: status: running
qm config 100 | grep -E "bios|machine|scsihw|net0"
# Expect: ovmf, q35, virtio-scsi-pci, pinned MAC
```

## 6. Data note

Automations/integrations/dashboards die with `qm destroy`. No VM backup in the initial build — see persistence-design.

## 7. FAQ

**Q: Why not Terraform this VM?**
A: `qm importdisk` needs the VMID to exist first, while Terraform wants to declare it — same class as managed templates. Manual `qm` is the supported path.

**Q: Stuck at "Booting from Hard Disk" with 50% CPU, 0 disk IO?**
A: Wrong BIOS/machine/controller — recreate with §3 flags exactly.

**Q: Got a different IP after rebuild?**
A: MAC changed (omitted `--net0` MAC pin) — reservation orphaned. Recreate with pinned MAC + reboot.
