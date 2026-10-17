---
id: ref-inventory
title: Inventory (no secrets)
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [reference, inventory]
retrievable: true
---

# Inventory (no secrets)

> What exists, where config lives, and which vault variable holds each secret. Values are never stored here.

## Proxmox

- Node `haytham`, bridge `vmbr0`, storage `local-lvm` (rootfs) + `local` (templates/ISO). Host `192.168.100.2`.
- Service account `terraform@pve!terraform` (privsep off). Roles: `PVEVMAdmin` on `/`, `PVESDNUser` on SDN zone, `PVEDatastoreUser` on `local` + `local-lvm`, `PVEAuditor` on `/` (for `query-url-metadata`).
- Template: `local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst` (downloaded manually via GUI, referenced as static string — see ADR-002).
- VM100 HAOS at `192.168.100.3` (DHCP reservation, MAC `BC:24:11:D7:75:C0`). VM block `.4-.10` reserved.

## Terraform

- Modules: `modules/lxc` (generic, `nesting=true`).
- Provider `bpg/proxmox ~> 0.111`. Local state (gitignored), `.terraform.lock.hcl` committed.
- Key files: `locals.tf` (CTID/IP/resources map + tier filters), `containers.tf` (per-tier `for_each`), `templates.tf` (static string only), `variables.tf` (`pve_endpoint`, `pve_api_token`, `ssh_public_key_path`, `ct_root_password`).

## Ansible

- Control node: WSL checkout (`ansible/`). Collections in `requirements.yml` (`community.postgresql`, `community.docker`).
- `ansible.cfg`: `remote_user=root`, `vault_password_file=.vault_pass` (gitignored, never shared).
- Vault pattern: single master password, per-value `encrypt_string`, one `group_vars/<tier>.yml` per tier.
- Vault variable index (names only):
  - tier10: `vault_pihole_webpassword`
  - tier20: `vault_postgres_superuser_password`, `vault_redis_password`, `vault_pgadmin_default_password`
  - tier30: `vault_vaultwarden_admin_token`
  - tier40: `vault_karakeep_nextauth_secret`, `vault_karakeep_meili_master_key`, `vault_karakeep_browser_token`

## SSL

- Wildcard `*.haytham.internal` self-signed. Key/crt/cnf in `~/homelab-cert/` (WSL) + Windows backup + Vaultwarden attachment after Tier 30. Imported to NPM as Custom Certificate.

## DNS

- Base `haytham.internal`. Flat pattern `<service>.haytham.internal`, root reserved for Homepage (future). `pve.haytham.internal` → `.2`.
- Wildcard `*.haytham.internal → 192.168.100.12` in Pi-hole (`/etc/dnsmasq.d/99-wildcard-haytham.conf`, `misc.etc_dnsmasq_d=true`).
- Router DHCP pool `.100–.254`. Router DNS stays ISP default until Pi-hole cutover.
