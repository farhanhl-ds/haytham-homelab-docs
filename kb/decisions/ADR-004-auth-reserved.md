---
id: adr-004-auth-reserved
title: ADR-004 — SSO Reserved (Not Built)
tier: "30"
ctid: "310"
ip: 192.168.100.31
status: planned
last_verified: unreleased
tags: [decision, sso, authentik, authelia, postiz]
retrievable: true
---

# ADR-004 — SSO Reserved (Not Built)

## Context

Tier 30 reserves CTID 310 for SSO. Candidates: Authentik (full IdP, heavier) vs Authelia (lightweight forward-auth to NPM/nginx, OIDC-capable). No app in the initial build requires OIDC/SSO; all run on native auth.

## Decision

Do not build SSO in the initial scope. Tier 30 is Vaultwarden only. CTID 310 / `.31` stays reserved with the research below so a future trigger does not restart from zero.

## Alternatives considered

- Authentik (viable if native SSO to many apps becomes wanted; runtime in the few-hundred-MB range, no Redis needed in current releases).
- Authelia (recommended default when a trigger appears: <30 MB, forward-auth to NPM, OIDC-viable).

## Consequences

- No SSO dependency for any initial-build app.
- Postiz stays out of scope with the same logic (needs Postgres + Redis + Temporal + app — heavy for narrow scheduling needs; native scheduling or lighter tools cover it). See `roadmap/future-services.md`.

## Status

Reserved. Trigger: concrete OIDC/SSO requirement.
