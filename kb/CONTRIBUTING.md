---
id: kb-contributing
title: Contributing to the Haytham KB
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [contributing, meta]
retrievable: false
---

# Contributing to the Haytham KB

This KB is designed for dual use: human operators and RAG/chatbot ingestion.

## Authoring rules

1. **English only.** All pages English.
2. **One concept per file.** If a file exceeds ~400 lines, split it.
3. **Frontmatter required.** Copy from `templates/frontmatter-reference.md`. New files start `status: planned / last_verified: unreleased`.
4. **Link, don't copy.** IPs, `qm create` flags, Terraform snippets live in exactly one canonical page. Elsewhere, link.
5. **No secrets.** Variable names (`vault_postgres_superuser_password`) OK. Values, `.vault_pass` contents, private keys — never.
6. **Timeless writing.** No history, dates, or incident narratives. Past problems belong as `Prerequisites` / `Constraints` / `Known gotchas` at the point of use. The only chronological page is `roadmap/build-sequence.md`.
7. **Every service page needs:** Purpose, Spec, Provisioning ref, Configuration, Verification, Gotchas, FAQ.
8. **Every runbook needs:** Purpose, When to use, Prerequisites, Steps, Verification, Rollback, Manual-gaps section.
9. **Status hygiene:** `planned` until its verification block passes on a clean build, then `verified` with date.
10. **KB-first fixes:** if you fix something via SSH/manual, port it to KB + IaC in the same session.

## File naming

- `architecture/<topic>.md` — kebab-case topic.
- `services/<tier>-<name>-<ctid>.md`, e.g. `data-postgres-210.md`. VM: `vm-haos-100.md`.
- `decisions/ADR-<nnn>-<slug>.md` — zero-padded, sequential.
- `troubleshooting/<slug>.md` — requirement-oriented slug (not migration/incident).

## RAG ingestion

- Ingest `kb/**/*.md` where `retrievable: true`. Ingest nothing outside `kb/` — `templates/` and `eval/` are excluded.
- Exclude `templates/` and `eval/`.
- Chunk on H2 (`##`), target 512–1024 tokens, 10% overlap.
- Use frontmatter (`tier`, `ctid`, `tags`, `status`) as metadata filters.
- Evaluate against `eval/qa-golden.md` after any embedding-model change.
