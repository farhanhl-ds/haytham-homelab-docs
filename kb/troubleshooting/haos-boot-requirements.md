---
id: ts-haos-boot-requirements
title: HAOS Boot Requirements (BIOS machine storage)
tier: "vm"
ctid: "100"
ip: 192.168.100.3
status: planned
last_verified: unreleased
tags: [troubleshooting, haos, vm, boot, uefi]
retrievable: true
---

# HAOS Boot Requirements (BIOS/machine/storage)

## 1. Required flags

Proxmox defaults mismatch the HAOS image build assumptions. All four overrides are mandatory at `qm create` time:

| Proxmox default | Required |
|---|---|
| SeaBIOS | `ovmf` (UEFI) |
| i440fx | `q35` |
| LSI 53C895A | `virtio-scsi-pci` |
| no EFI disk | `efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=0` |

Exact command + GUI attach/boot-order steps: `services/vm-haos-100.md §3`.

## 2. Failure signature if skipped

Stuck at "Booting from Hard Disk...", sustained ~50% CPU, flat 0% disk IO. Pattern = BIOS sees a device but cannot interpret it. Do not chase `--cpu` variants — recreate the shell with the four flags.

## 3. FAQ

**Q: Can I change these on a running VM?**
A: Recreate the shell cleanly. Half-migrated BIOS/disk pairings cost more time than a rebuild (the qcow2 is reused, no re-download).
