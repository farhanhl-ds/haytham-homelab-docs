---
id: arch-ansible-strategy
title: Ansible Strategy
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [architecture, ansible, vault, wsl]
retrievable: true
---

# Ansible Strategy

## 1. Control node

- WSL checkout of the repo (`ansible/` directory), not Windows native.
- Terraform runs on Windows; Ansible runs on WSL. They have **separate `~/.ssh/` directories** — the most common auth failure is using the wrong filesystem's key.
- The key baked into containers is the Windows `~/.ssh/id_ed25519.pub` (via `ssh_public_key_path` at `apply` time). Before running playbooks: copy the Windows private key to WSL `~/.ssh/id_ed25519` (`chmod 600`) and confirm `ansible_ssh_private_key_file: ~/.ssh/id_ed25519` in `group_vars/all.yml`.
- Fresh WSL setup: `apt install -y ansible openssh-client bind9-dnsutils postgresql-client redis-tools`, then `ansible-galaxy collection install -r requirements.yml`.

## 2. Layout

```
ansible/
  ansible.cfg (.vault_pass via vault_password_file, remote_user=root)
  README.md (control-node setup + secrets bootstrap)
  .vault_pass (plaintext, gitignored, never zipped/shared — create with openssl rand)
  inventory/hosts.yml (tier10/20/30/40 groups with static IPs from the matrix)
  group_vars/{all.yml, tier10.yml, tier20.yml, tier30.yml, tier40.yml}
  tier10.yml, tier20.yml, tier30.yml, tier40.yml (entry playbooks, tier order)
  roles/{pihole, npm, postgres, redis, pgadmin, docker, vaultwarden, karakeep}/
  requirements.yml (community.postgresql, community.docker)
```

Run order is always `tier10 → tier20 → tier30 → tier40`.

## 3. Vault pattern

Single master password for all tiers. Per-value `encrypt_string`, one file per tier mixing plaintext + `!vault` blocks:

```bash
openssl rand -base64 24 > .vault_pass && chmod 600 .vault_pass
SECRET1=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
ansible-vault encrypt_string "$SECRET1" --name 'vault_pihole_webpassword'
# paste resulting !vault block into group_vars/tier10.yml
unset SECRET1; history -c
```

Rules: generate with `openssl rand`, never paste values into chat, `unset SECRET; history -c` after each. Encrypted blocks are safe to commit (unlike `terraform.tfvars`). `CHANGEME` placeholders in a fresh checkout mean "generate now".

Read one value with:

```bash
ansible localhost -m debug -a "var=vault_pgadmin_default_password" -e @group_vars/tier20.yml --vault-password-file .vault_pass
```

(`ansible-vault view` only works for whole-file encryption, not this pattern.)

## 4. Reusable roles

- `roles/docker` (official apt repo install) consumed via `meta/main.yml` dependencies by `npm`, `pgadmin`, `vaultwarden`, `karakeep`. Fix Docker install in exactly one place.
- `community.postgresql` for DB/user provisioning; `community.docker.docker_compose_v2` for compose (not raw `command`).
- Cross-tier scoping constraint: `group_vars` are per-inventory-group. A var in `tier20.yml` is invisible to `tier30` hosts. If a future app consumes Tier 20 from another tier, duplicate the value under a tier-scoped name with identical plaintext (generate once, encrypt twice).

## 5. Reproducibility rule

Every manual/SSH fix must be ported back to a role in the same session. Full build with `failed=0` on every playbook is the acceptance gate.

## 6. FAQ

**Q: Ansible fails auth right after Terraform succeeded?**
A: Wrong key filesystem (Windows vs WSL). Verify `ansible_ssh_private_key_file` points at the baked-in private key.

**Q: How do I rotate one secret?**
A: See `operations/secret-rotation.md` — usually re-`encrypt_string` + re-run the owning playbook, except pgAdmin password (first-run only).
