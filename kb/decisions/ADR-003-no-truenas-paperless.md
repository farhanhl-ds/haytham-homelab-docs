---
id: adr-003-no-truenas-paperless
title: ADR-003 — No TrueNAS, Paperless-ngx Skipped
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [decision, storage, truenas, paperless]
retrievable: true
---

# ADR-003 — No TrueNAS, Paperless-ngx Skipped

## Context

Target hardware is a single-disk mini PC (1× 2.5" bay + 1× M.2).

## Decision

- Skip TrueNAS until additional storage hardware exists (ZFS needs ≥2 disks for redundancy benefit).
- Skip Paperless-ngx (no defined need). CTID 450 stays reserved (see `roadmap/future-services.md`).

## Alternatives considered

- Single-disk ZFS (rejected: no redundancy, ops burden without benefit).

## Consequences

- No NAS/storage layer in the initial build; persistence design stays explicit (see `architecture/persistence-design.md`).

## Status

Accepted. Revisit on hardware change (TrueNAS) or concrete need (Paperless-ngx).
