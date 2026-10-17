---
id: ops-build-from-scratch
title: Runbook — Build Homelab from Scratch
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [operations, build, terraform, ansible]
retrievable: true
---

# Runbook — Build Homelab from Scratch

> Procedural only. For rationale see `architecture/` and `decisions/`. Canonical per-service config lives in `services/` — if this runbook diverges, `services/` wins.
>
> **Read §8 Destroy = data loss before step 1 on any loaded system.**

## 1. When to use / not use

- Use: initial build, full validation, disaster recovery drill.
- Do not use `-target` for full builds (only for exceptional partial work). Plain `terraform apply` / `terraform destroy` is the supported path.
- VM 100 (HAOS) is not covered by Terraform steps — see §4.

## 2. Prerequisites

- Proxmox host at `192.168.100.2`, node `haytham`, `vmbr0`, `local` + `local-lvm`. Template `local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst` downloaded via GUI.
- Service account `terraform@pve!terraform` with the four role grants (see `terraform-strategy.md`).
- SSH key pair. The public key path is passed to Terraform; the private key must exist in both Windows and WSL (`chmod 600` in WSL).
- WSL tooling: `ansible openssh-client bind9-dnsutils postgresql-client redis-tools`, plus `ansible-galaxy collection install -r requirements.yml`.
- Filled `terraform.tfvars` (`pve_endpoint=https://192.168.100.2:8006/`, `pve_api_token`, absolute `ssh_public_key_path`, `ct_root_password` via env or prompt).
- Secrets: `.vault_pass` created, every `CHANGEME` in `group_vars/*.yml` replaced via `encrypt_string` (see `ansible-strategy.md`).
- SSL cert generated (`~/homelab-cert/` + Windows backup) — needed for the NPM manual step.
- Router: DHCP pool `.100-.254`, reservation MAC `BC:24:11:D7:75:C0` → `.3`. Router DNS stays ISP default until §7 passes.
- qcow2 for HAOS in `/var/lib/vz/template/iso` (download from HAOS GitHub releases, `xz -d`).

## 3. Step 0 — Workstation DNS (before touching Pi-hole)

Destroying or absent Pi-hole while the workstation resolves only via Pi-hole = circular failure. Set safe mode first:

```powershell
# Safe-to-build (public first; internal names will NOT resolve yet)
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("1.1.1.1", "192.168.100.11")
# Normal use (Pi-hole first) — restore after §6 verifies green
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("192.168.100.11", "1.1.1.1")
ipconfig /flushdns
```

Requires Administrator. Detail: `dns-workstation-swap.md`.

## 4. Step 1 — Provision LXC with Terraform

```bash
terraform init
terraform validate
terraform plan
# Expect: 7 LXC (110, 120, 210, 220, 230, 320, 420), 0 errors
terraform apply
```

`ssh_public_key_path` must be absolute — Terraform `file()` does not expand `~`.

Known gotcha (single-node `local-lvm`): Terraform creates all LXC in parallel, but local storage serializes allocations under one lock. A container may fail with `can't lock file .../pve-storage-local-lvm - got timeout` while its siblings succeed. This is contention, not misconfiguration — re-run `terraform apply` (state already holds the successes, so only the missing containers are retried; each run converges). To avoid a second storm, retry serially: `terraform apply -parallelism=1`.

## 5. Step 2 — VM 100 HAOS (manual, parallel track)

Canonical spec: `services/vm-haos-100.md`. Summary:

```bash
ls /var/lib/vz/template/iso/*.qcow2

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
# GUI: VM100 → Hardware → Unused Disk 0 → Edit → Discard → Add
# GUI: Options → Boot Order → scsi0 top, checked
qm start 100
```

Console reaches `System is ready` in 2–5 min at `http://192.168.100.3:8123`.

Example next VM (first free in `.4-.10`): `qm clone` or `qm create 101 --name devbox` with router reservation for `.4` before start.

## 6. Step 3 — SSH known-hosts + Ansible

From WSL:

```bash
for ip in 192.168.100.11 192.168.100.12 192.168.100.21 192.168.100.22 192.168.100.23 192.168.100.32 192.168.100.42; do
  ssh-keygen -f ~/.ssh/known_hosts -R "$ip"
done
```

From the repo `ansible/` directory:

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook tier10.yml
ansible-playbook tier20.yml
ansible-playbook tier30.yml
ansible-playbook tier40.yml
# Expect: failed=0 on all hosts
```

Vaultwarden flow: set `vaultwarden_signups_allowed` to `"true"` → create master account → set `"false"` → re-run `tier30.yml`.

## 7. Step 4 — Verify end-to-end

```bash
dig karakeep.haytham.internal @192.168.100.11 +short
# Expect: 192.168.100.12
psql -h 192.168.100.21 -U postgres -c "SELECT 1;"
redis-cli -h 192.168.100.22 -a '<password>' ping
# Expect: PONG
ssh root@192.168.100.12 "docker ps"  # npm
ssh root@192.168.100.23 "docker ps"  # pgadmin
ssh root@192.168.100.32 "docker ps"  # vaultwarden
ssh root@192.168.100.42 "docker ps"  # karakeep (3, healthy)
qm status 100  # Expect: running
```

Browser (DNS → Pi-hole): `https://{pihole,npm,pgadmin,vaultwarden,karakeep}.haytham.internal` + `http://192.168.100.3:8123`.

## 8. Step 5 — Manual gaps (redo per rebuild, cannot be IaC'd)

- **NPM (.12):** admin account → import `haytham-internal` cert → 5 Proxy Hosts (see `services/network-npm-120.md §4`) → pihole custom location `rewrite ^/$ /admin permanent;` → vaultwarden websockets ON.
- **pgAdmin (.23):** login preseeded, but Server connection re-add: `192.168.100.21:5432`, user `postgres`.
- **Vaultwarden (.32):** create master account, then `signups_allowed=false` + re-run tier30.
- **Karakeep (.42):** self-register; bookmarks re-entered manually (no restore).
- **HAOS:** onboarding wizard; automations lost on rebuild.
- **Workstation:** restore Normal DNS order (§3).

## 9. Destroy = data loss

All data is in container/VM disks (see `architecture/persistence-design.md`). This runbook validates config, not durability. For Vaultwarden with real secrets, export the vault to an encrypted file before any `terraform destroy` / `qm destroy`.
