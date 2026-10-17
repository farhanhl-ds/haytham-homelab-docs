# Haytham Homelab — Ansible

Recreated 2026-10-14 from `kb/` after the original project (`~/homelab/ansible/V2`
on WSL) was lost in a Windows reinstall with no backup. This directory replaces
that path — run it from a WSL checkout of this repo.

## Layout

```
ansible/
  ansible.cfg            # remote_user=root, vault_password_file=.vault_pass
  .vault_pass            # YOU CREATE THIS (plaintext, gitignored) — see §2
  inventory/hosts.yml    # tier10/20/30/40 groups with static IPs
  group_vars/            # all.yml + one file per tier (vault pattern below)
  tier10/20/30/40.yml    # entry playbooks, one play per host
  roles/                 # docker, pihole, npm, postgres, redis, pgadmin,
                         # vaultwarden, karakeep (infisical deferred, see kb/)
  requirements.yml       # community.postgresql, community.docker
```

Role ↔ KB spec: `docker`+`pihole`+`npm` → Tier 10 pages, `postgres`+`redis`+`pgadmin` →
Tier 20, `vaultwarden` → Tier 30, `karakeep` → Tier 40. Troubleshooting
in `kb/troubleshooting/`, runbooks in `kb/operations/`.

## 1. Control node setup (fresh WSL)

```bash
sudo apt install -y ansible openssh-client bind9-dnsutils postgresql-client redis-tools
ansible-galaxy collection install -r requirements.yml
# SSH key: the key baked into containers is the WINDOWS id_ed25519.pub
# (terraform ssh_public_key_path). Copy the private half to WSL:
cp /mnt/c/Users/<you>/.ssh/id_ed25519 ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
```

## 2. Secrets bootstrap (old vault is UNRECOVERABLE — generate everything fresh)

```bash
# master vault password (single password for all tiers)
openssl rand -base64 24 > .vault_pass
chmod 600 .vault_pass

# per-secret values — repeat for EVERY CHANGEME in group_vars/*.yml:
SECRET1=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
ansible-vault encrypt_string "$SECRET1" --name 'vault_pihole_webpassword'
# paste the !vault block over the CHANGEME line, then:
unset SECRET1; history -c
```

Cross-tier rule (for future Tier 30 consumers of Tier 20): vars in one
`group_vars` file are invisible to other inventory groups — duplicate shared
values under group-scoped names with identical plaintext.
Full procedure: `kb/operations/rebuild-from-scratch.md` (Step 5) and
`kb/operations/secret-rotation.md`. Never paste generated values into AI chat.

`CHANGEME` values are inert placeholders — safe to commit, useless to anyone.

## 3. Run order

```bash
ansible-playbook tier10.yml
ansible-playbook tier20.yml
ansible-playbook tier30.yml
ansible-playbook tier40.yml
# Expect: failed=0 on all hosts. Verify per kb/operations/rebuild-from-scratch.md.
```

## 4. First-deploy caveats (reconstructed code, battle-test pending)

- `roles/karakeep` is pinned to upstream v0.33.2 (env verified 2026-10-14);
  bump `karakeep_version` in role defaults to upgrade (check release notes first).
  schemas — confirm against the pinned image docs before first deploy, then
  remove the notices.
- Vaultwarden: flip `vaultwarden_signups_allowed` to `"true"` for the first
  account, then back to `"false"` + re-run (see role defaults).
- pgAdmin password rotation is UI-only (first-run preseed, see KB).
- Status: **draft** until a full destroy+rebuild proves `failed=0` end-to-end.
  Then update this README + `kb/roadmap/phase2-in-progress.md`.

## 5. No-WSL alternatives (ranked)

1. **Install WSL2 + Ubuntu (recommended).** Native path this project is designed
   for; 10 minutes, reusable for every future rebuild:
   ```powershell
   # Administrator PowerShell, then reboot when prompted:
   wsl --install -d Ubuntu-24.04
   ```
   Then continue at §1 inside the Ubuntu shell.
2. **Temporary LXC control node on Proxmox.** Create any Ubuntu 24.04 LXC from
   the GUI, `apt install ansible`, clone/copy this repo + `ansible/` into it,
   bootstrap §1–§2 there. Delete it after the battle test (or keep it out of
   Terraform so it survives `terraform destroy`). Pragmatic if WSL fights you.
3. **Proxmox host shell (last resort).** `pip install ansible` on `haytham`
   works but pollutes the hypervisor — avoid unless options 1–2 are blocked.
4. **NOT recommended:** Git Bash/Cygwin (dependency pain) or Docker Desktop
   on Windows (needs the WSL2 backend anyway — at that point just use option 1).
