---
id: adr-006-infisical-deferred
title: ADR-006 — Infisical Deferred
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [decision, infisical, secrets-manager]
retrievable: true
---

# ADR-006 — Infisical Deferred

## Context

Tier 30 reserves CTID 330 (`192.168.100.33`) for a machine secrets manager (Infisical was the initial candidate). Infisical offers centralized secret rotation beyond Ansible Vault's per-value pattern. However, no app in the initial build requires it — Karakeep and Vaultwarden are SQLite-only, Postgres DB credentials live in `group_vars/tier20.yml`, and NPM admin is not in Vault.

## Decision

Do not build Infisical in the initial scope. Tier 30 is Vaultwarden only. CTID 330 / `.33` stays reserved.

When a trigger appears (consumers beyond Ansible Vault, rotation pain), revive with:

1. Add `infisical` block to `locals.tf` containers (CTID 330, `192.168.100.33`).
2. `terraform apply`.
3. Add `infisical` to `ansible/inventory/hosts.yml` tier30 group.
4. Duplicate shared Tier 20 secret values under tier-scoped names in `group_vars/tier30.yml` (generate once, encrypt twice — plaintext identical).
5. Write `roles/infisical` (reusing `roles/docker`).
6. Add `tier30.yml` play entry or new playbook.
7. Add NPM Proxy Host `infisical.haytham.internal → 192.168.100.33:80`.

## Alternatives considered

- Build Infisical now (rejected: no consumer, adds operational burden without benefit).
- HashiCorp Vault (rejected: over-engineered for single-user homelab).

## Consequences

- No machine secrets manager in the initial build.
- `postgres_databases: []` in `group_vars/tier20.yml` (no shared-PG consumers yet).
- Revival path is documented here so a future trigger does not restart from zero.

## Status

Reserved. Trigger: concrete secrets-manager requirement beyond Ansible Vault.
