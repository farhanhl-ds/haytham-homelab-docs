---
id: ops-secret-rotation
title: Runbook — Secret Rotation
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [operations, security, vault, rotation]
retrievable: true
---

# Runbook — Secret Rotation

## 1. Purpose

Rotate the Ansible Vault master password and/or individual secrets. Covers the pgAdmin first-run exception.

## 2. Hygiene rules (apply from day one)

- Any secret exposed outside its intended store counts as compromised — regenerate, not just re-wrap.
- Exclude `.vault_pass` from every archive: `zip -r project.zip . -x ".vault_pass"` (`.gitignore` does not protect `zip`).
- Never paste generated values into chat or logs. Generate, encrypt, then `unset SECRET; history -c`.

## 3. Rotate master password only (re-wrap same values)

```bash
cd ansible
ansible-vault rekey group_vars/tier10.yml
ansible-vault rekey group_vars/tier20.yml
ansible-vault rekey group_vars/tier30.yml
ansible-vault rekey group_vars/tier40.yml
# update .vault_pass file to new password (gitignored, local only)
```

No service restart needed (values unchanged, only wrapping changed).

## 4. Regenerate individual secrets (new values)

```bash
SECRET1=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
ansible-vault encrypt_string "$SECRET1" --name 'vault_karakeep_nextauth_secret'
# paste !vault block into group_vars/tier40.yml, replacing old block
unset SECRET1; history -c
```

Then re-run the owning playbook:

```bash
ansible-playbook tier10.yml  # etc. per tier
```

Cross-tier constraint: if an app ever consumes another tier's secret, both copies must share plaintext (generate once, encrypt twice under tier-scoped names). No such pairs exist in the initial build.

## 5. Exceptions

- **pgAdmin login password:** `PGADMIN_DEFAULT_PASSWORD` applies on first run only. Vault change + re-run is ignored for existing accounts. Rotate via UI (User Management → Change Password) or wipe `./data` to replay first run.
- **NPM admin:** not in Vault at all (SQLite in container). Change in NPM UI.
- **Service self-registrations** (Vaultwarden master, Karakeep user): app-level accounts, rotated in-app, not via Vault.

## 6. Verification

- Read-back check (never `cat` vault files for values):
  ```bash
  ansible localhost -m debug -a "var=vault_pgadmin_default_password" -e @group_vars/tier20.yml --vault-password-file .vault_pass
  ```
- Login smoke per service (see each `services/*.md §5`).

## 7. FAQ

**Q: Rekey or regenerate?**
A: Rekey = same secrets, new master password (fast, `.vault_pass` exposure only). Regenerate = new secret values (required if a secret value itself was exposed).
