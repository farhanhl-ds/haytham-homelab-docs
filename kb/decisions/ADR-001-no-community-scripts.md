---
id: adr-001-no-community-scripts
title: ADR-001 — No Direct Use of community-scripts
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [decision, community-scripts, iac]
retrievable: true
---

# ADR-001 — No Direct Use of community-scripts

## Context

`community-scripts.org` offers fast per-app LXC provisioning.

## Decision

Do not execute install scripts directly. Reference their `install/*.sh` logic as input for Ansible roles where useful.

## Alternatives considered

- Direct script execution (rejected: interactive/whiptail, non-idempotent, untracked in Terraform state — conflicts with IaC).

## Consequences

- Slower initial provisioning, but reproducible (`destroy` + `rebuild` clean).
- Ansible roles take longer to write; upstream install scripts shorten research.

## Status

Accepted. Revisit only if idempotent non-interactive Terraform-compatible modules are published.
