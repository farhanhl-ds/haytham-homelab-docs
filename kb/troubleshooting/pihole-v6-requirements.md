---
id: ts-pihole-v6-requirements
title: Pi-hole v6 Requirements
tier: "10"
ctid: "110"
ip: 192.168.100.11
status: planned
last_verified: unreleased
tags: [troubleshooting, pihole, dns]
retrievable: true
---

# Pi-hole v6 Requirements

Build the role against these v6 behaviors from the start — they are requirements, not fixes:

## 1. Password command

- Use `pihole setpassword <pw>` (idempotent, `no_log: true`).
- `pihole -a -p` (v5) exits 0 but does not authenticate on v6 (auth moved to `/etc/pihole/pihole.toml`).

## 2. Gravity

- Run `pihole -g` with retries. Unattended installs sometimes skip gravity; symptom is "Domains on Lists: Error (-2)". Success shows tens of thousands of domains.

## 3. Wildcard via dnsmasq file, not UI

- Web UI Local DNS handles exact domains only.
- Required file `/etc/dnsmasq.d/99-wildcard-haytham.conf` (`server=/haytham.internal/#` + `address=/.haytham.internal/192.168.100.12`).

## 4. v6 ignores that directory by default

- Required: `pihole-FTL --config misc.etc_dnsmasq_d true` + `pihole-FTL` restart.

## 5. Verify correctly

- `dig <name> @<pihole-ip>` queries that Pi-hole directly. Browser/OS tests are invalid until the OS resolver points at Pi-hole.

## 6. FAQ

**Q: Task succeeded but login fails?**
A: The role used the v5 password command. Switch to `setpassword`.
