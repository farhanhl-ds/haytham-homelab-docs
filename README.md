# Haytham Homelab

Single-node Proxmox VE homelab. Infrastructure as Code with Terraform (LXC shells) and Ansible (app configuration), tiered across Network, Data, Identity, and Application layers.

## Architecture

```
Terraform (bpg/proxmox)     →     Ansible (control node)
LXC shell, CPU/RAM/disk     →     Package install, app config
Network + static IP         →     Systemd units, compose files
Cloud-init user + SSH key   →     App users/permissions
```

Terraform stops when each container exists with the correct IP and is SSH-reachable. Everything after is Ansible (one role per app, idempotent).

## Tier Map

| Tier | Scope | Services | CTIDs | IPs |
|------|-------|----------|-------|-----|
| 10 | Network / Ingress | Pi-hole, NPM | 110, 120 | .11, .12 |
| 20 | Data / Persistence | Postgres, Redis, pgAdmin | 210, 220, 230 | .21, .22, .23 |
| 30 | Identity & Access | Vaultwarden | 320 | .32 |
| 40 | Application | Karakeep | 420 | .42 |
| VM | Home Assistant OS | HAOS (manual `qm`) | 100 | .3 |

Domain base: `haytham.internal` (RFC 9476, reserved for private use). Wildcard `*.haytham.internal → NPM (.12)` via Pi-hole DNS. One wildcard self-signed cert reused across all NPM Proxy Hosts.

## Directory Layout

```
homelab/
├── terraform/          # Proxmox LXC provisioning
│   ├── terraform.tfvars.example   # copy → terraform.tfvars (gitignored)
│   ├── service-account.txt        # Proxmox API token (gitignored)
│   ├── providers.tf, variables.tf, locals.tf, containers.tf
│   ├── templates.tf               # static template reference
│   ├── versions.tf, .terraform.lock.hcl (committed)
│   └── modules/lxc/               # reusable LXC module
├── ansible/             # App configuration
│   ├── ansible.cfg, inventory/hosts.yml
│   ├── group_vars/tier{10,20,30,40}.yml  # vault-encrypted secrets
│   ├── tier10/20/30/40.yml        # entry playbooks
│   ├── roles/{docker,pihole,npm,postgres,redis,pgadmin,vaultwarden,karakeep}/
│   ├── requirements.yml           # community.postgresql, community.docker
│   └── .vault_pass (gitignored), collections/ (gitignored)
└── kb/                  # Knowledge base
    ├── architecture/, services/, operations/, decisions/, roadmap/
    ├── reference/, troubleshooting/, templates/, eval/
```

## Build Sequence (high level)

1. Install Proxmox, configure `vmbr0`, download Ubuntu 24.04 CT template via GUI.
2. Create `terraform@pve!terraform` service account with role grants.
3. Generate wildcard SSL cert `*.haytham.internal`.
4. `cp terraform/terraform.tfvars.example terraform/terraform.tfvars` and fill in secrets.
5. `terraform init && terraform apply` — provisions 7 LXC.
6. From the Ansible control node (WSL): `ansible-playbook tier10.yml → tier20.yml → tier30.yml → tier40.yml`.
7. Manual gaps (cannot be IaC'd): NPM proxy hosts + cert import, pgAdmin server connection, Vaultwarden master account, Karakeep registration, HAOS VM.

Full runbook: `kb/operations/build-from-scratch.md`.

## Secrets Handling

| Secret | Location | Gitignored? |
|--------|----------|-------------|
| Proxmox API token | `terraform/terraform.tfvars` | ✅ |
| Proxmox service account details | `terraform/service-account.txt` | ✅ |
| Terraform state | `terraform/*.tfstate*` | ✅ |
| Ansible Vault master password | `ansible/.vault_pass` | ✅ |
| Per-value encrypted secrets | `ansible/group_vars/tier*.yml` (`!vault` blocks) | ❌ (safe to commit) |

Rules:
- Generate secrets with `openssl rand`, never paste values into chat or logs.
- `unset SECRET; history -c` after each generation.
- `.vault_pass` excluded from all archives (`zip -r … -x .vault_pass`).
- Encrypted `!vault` blocks are safe to commit; only the master password in `.vault_pass` is sensitive.

## Prerequisites

**Terraform machine:**
- `terraform >= 1.7.0`
- SSH agent with key-based `root@<proxmox-host>` access

**Ansible control node (recommended: WSL Ubuntu 24.04):**
- `ansible`, `openssh-client`, `bind9-dnsutils`, `postgresql-client`, `redis-tools`
- `ansible-galaxy collection install -r requirements.yml`
- Private key matching the public key baked into containers via Terraform

## Knowledge Base

All documentation lives in `kb/`. Entry points:

- `kb/index.md` — index and how to use the KB
- `kb/architecture/overview.md` — architecture overview
- `kb/architecture/terraform-strategy.md` — Terraform provider, state, service account
- `kb/architecture/ansible-strategy.md` — Ansible control node, vault pattern, run order
- `kb/roadmap/build-sequence.md` — the only chronological build document
- `kb/decisions/` — ADRs for structural choices
- `kb/operations/` — runbooks (build from scratch, secret rotation, update/reboot, DNS swap)
- `kb/reference/ip-ctid-matrix.md` — canonical IP ↔ CTID ↔ hostname matrix

## Status

All KB pages are `planned` / `unreleased` until a full `destroy` + `rebuild` proves `failed=0` end-to-end. Flip to `verified` with date after a green build.

## Contributing

- KB-first fixes: if you fix via SSH/manual, port it to KB + IaC in the same session.
- One concept per file, frontmatter required, no secrets in KB.
- English only, RAG-ready markdown.
