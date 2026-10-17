---
id: adr-005-haos-manual
title: ADR-005 — HAOS Managed Manually via qm, Not Terraform
tier: "vm"
ctid: "100"
ip: 192.168.100.3
status: planned
last_verified: unreleased
tags: [decision, haos, vm, terraform, qm]
retrievable: true
---

# ADR-005 — HAOS Managed Manually via qm, Not Terraform

## Context

HAOS is a full OS image (`qcow2`), not `apt`/`compose`. It requires a VM (cleaner USB passthrough for future Zigbee/Z-Wave). `qm importdisk` needs the VMID to exist first, while Terraform wants to declare it — the same class as managed templates (ADR-002).

## Decision

Manage VM 100 fully manually (`qm create` / `importdisk` / GUI disk attach / boot order). Document canonically in `services/vm-haos-100.md`; Terraform ignores it. IP is a router reservation (`.3`, MAC-pinned), not Terraform state.

## Alternatives considered

- Terraform-managed VM (rejected: import lifecycle friction, no precedent in supported guides).

## Consequences

- The build runbook has a separate manual VM section; the VM is excluded from `terraform destroy` scope.
- Identity stability via pinned MAC (reservation-safe), consistent with IaC philosophy.

## Status

Accepted.
