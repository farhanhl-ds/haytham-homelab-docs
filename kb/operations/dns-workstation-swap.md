---
id: ops-dns-workstation-swap
title: Note — DNS Workstation Swap (resolver order)
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [operations, dns, windows, pihole]
retrievable: true
---

# Note — DNS Workstation Swap (resolver order)

## 1. Rule

Clients stop at the **first definitive answer** (including NXDOMAIN). Secondary is only tried if primary is **unreachable** (timeout), not on "not found".

## 2. Two modes (swap manually)

```powershell
# Safe-to-build (public first; internal names will NOT resolve)
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("1.1.1.1", "192.168.100.11")
# Normal use (Pi-hole first; internal names resolve; public is fallback if Pi-hole down)
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("192.168.100.11", "1.1.1.1")
ipconfig /flushdns
```

Requires Administrator (CIM error = not elevated, not a network bug).

## 3. When to swap

- Before any work touching Pi-hole → safe mode.
- After rebuild verifies green (`dig @192.168.100.11` passes) → normal mode.
- Manual per-device step. Router-level DNS waits until multi-device need (blast radius), so this stays per-device.

## 4. FAQ

**Q: Pi-hole is listed but internal names fail?**
A: Check order — a public resolver first authoritatively NXDOMAINs `*.haytham.internal` and the client never asks Pi-hole.
