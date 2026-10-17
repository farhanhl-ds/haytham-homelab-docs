---
id: adr-002-manual-template
title: ADR-002 — Templates Managed Manually, Referenced Statically
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [decision, terraform, template]
retrievable: true
---

# ADR-002 — Templates Managed Manually, Referenced Statically

## Context

OS templates could be managed via `proxmox_virtual_environment_download_file`, but the Proxmox API stores no origin URL for template files.

## Decision

Download the template once via Proxmox GUI; reference it as a static string (`local:vztmpl/<file>`) in `templates.tf`. No lifecycle management in Terraform.

## Alternatives considered

- Managed download resource (rejected: import leaves `url` unknown; every plan shows replace; removing it from config risks deleting the file without `state rm`).

## Consequences

- Pro: clean plans, no surprise replaces.
- Con: deleted template = loud `apply` failure ("not found"), no auto re-download. Acceptable for single-node, rare-rebuild homelab: re-download via GUI and update the string.

## Status

Accepted.
