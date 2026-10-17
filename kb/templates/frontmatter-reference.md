---
# Frontmatter reference — copy this block to the top of every KB content file.
# No secrets in frontmatter. New files start planned/unreleased; flip to verified with date after green build.
id: unique-slug-here            # e.g. svc-pihole-110, arch-ip-scheme, adr-001, ops-build
title: Human-Readable Title
tier: "10"                      # "10"|"20"|"30"|"40"|"50"|"60"|"90"|"vm"|"x" (x = cross-cutting)
ctid: "110"                     # CTID string or "100" for VM or "n/a"
ip: 192.168.100.11             # or n/a
status: planned                 # planned | verified | reserved | deprecated
last_verified: unreleased       # YYYY-MM-DD once verified
tags: [pihole, dns, tier10]     # lowercase, hyphenated
retrievable: true               # false for templates/eval/meta
---
