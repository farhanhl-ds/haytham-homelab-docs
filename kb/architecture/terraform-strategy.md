---
id: arch-terraform-strategy
title: Terraform Strategy
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [architecture, terraform, proxmox, iac]
retrievable: true
---

# Terraform Strategy

## 1. Provider and state

- Provider `bpg/proxmox ~> 0.111` (not `telmate/proxmox` — unmaintained). Re-verify the current version before writing new config; training data goes stale fast.
- Local state, gitignored (`*.tfstate*`, `.terraform/`). `.terraform.lock.hcl` committed. Back up state separately — loss means per-container `terraform import`.
- Storage `local-lvm` (rootfs), bridge `vmbr0`, static IPs in Terraform, Ubuntu 24.04 LTS template.
- Endpoint is `https://192.168.100.2:8006/` (Proxmox host at `.2`).

## 2. Service account

User `terraform@pve`, token `terraform@pve!terraform`, privsep OFF. Use built-in roles scoped per path (do not build custom aggregated roles — they miss `Datastore.AllocateTemplate`):

```bash
pveum user add terraform@pve
pveum aclmod / -user terraform@pve -role PVEVMAdmin
pveum aclmod /sdn/zones/localnetwork -user terraform@pve -role PVESDNUser
pveum aclmod /storage/local -user terraform@pve -role PVEDatastoreUser
pveum aclmod /storage/local-lvm -user terraform@pve -role PVEDatastoreUser
pveum aclmod / -user terraform@pve -role PVEAuditor  # Sys.Audit for query-url-metadata
pveum user token add terraform@pve terraform --privsep 0
```

`PVEAuditor` is mandatory — without `Sys.Audit`, template download endpoints return 403.

Provider requires SSH for some LXC operations outside REST. The machine running `terraform apply` must have key-based `root@192.168.100.2` SSH working with `ssh agent = true`.

## 3. Project layout

```
terraform/
  versions.tf, providers.tf (insecure=true, ssh agent root)
  variables.tf (pve_endpoint, pve_api_token, ssh_public_key_path, ct_root_password)
  locals.tf (domain, target_node=haytham, network{}, containers{} + tier filters)
  templates.tf (static string only — see §4)
  containers.tf (per-tier module for_each)
  modules/lxc/{versions.tf, main.tf, variables.tf, outputs.tf}
```

`modules/lxc/versions.tf` must declare `required_providers` (child modules do not inherit source — Terraform guesses `hashicorp/proxmox` from the resource prefix otherwise).

Per-tier call pattern (`for_each` over filtered locals; adding a container = new entry in `locals.tf`, no `containers.tf` edit; new tier file needs `terraform init`):

```hcl
module "tier10" {
  source = "./modules/lxc"
  for_each = local.tier10_containers
  node_name = local.target_node
  vm_id = each.value.ctid
  # ... cores/memory/disk/datastore/bridge/ip/gateway/template/os_type/ssh/tags
  nesting = true
}
```

`nesting = true` on all Ubuntu 24.04 containers (declarative, not `pct set`) — see `troubleshooting/docker-in-lxc.md`. Pass `ssh_public_key_path` as an absolute path: Terraform `file()` does not expand `~`.

## 4. Template lifecycle (ADR-002)

Templates are downloaded manually via GUI (`Datacenter → node → local → CT Templates`) and referenced as:

```hcl
locals { template_ubuntu_2404 = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst" }
```

Do not manage templates with `proxmox_virtual_environment_download_file`: the API stores no origin URL, so the imported resource always shows `url` unknown and every plan wants to replace it. Trade-off: if the template file is deleted, `apply` fails loudly instead of re-downloading — that is the intended signal to re-download via GUI and update the string.

## 5. FAQ

**Q: Apply fails with Datastore.AllocateTemplate 403?**
A: Custom role missed it. Use the built-in roles in §2.

**Q: Plan wants to replace a download_file resource?**
A: Expected for managed templates — that is why templates stay unmanaged per §4.
