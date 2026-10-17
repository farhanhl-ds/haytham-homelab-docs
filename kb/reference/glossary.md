---
id: ref-glossary
title: Glossary
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [reference, glossary]
retrievable: true
---

# Glossary

| Term | Meaning |
|---|---|
| CTID | Proxmox container ID. Bookkeeping identity, not exposed in DNS. Tiered in steps of 10 (110, 120, 210…). |
| Tier | Logical layer: 10 Network/Ingress, 20 Data, 30 Identity, 40 App, 50 AI/ML (reserved), 60 Media (reserved), 70 CI/CD (reserved), 80 Backup (reserved), 90 Observability (reserved). |
| VM block | `.3` VM100 + `.4-.10` reserved. VMs take first free IP; CTID formula does not apply. |
| HAOS | Home Assistant OS, runs as VM 100 at `.3`. Manual `qm` management. |
| NPM | Nginx Proxy Manager (LXC 120 at `.12`). Reverse proxy + SSL termination for all HTTP services. |
| Pi-hole | DNS + adblock (LXC 110 at `.11`). Authoritative for `*.haytham.internal` via wildcard. |
| IaC | Infrastructure as Code — Terraform (shells) + Ansible (config). |
| `nesting` | LXC feature flag required for systemd on Ubuntu 24.04. Set declaratively in Terraform. |
| Vault (Ansible) | `ansible-vault encrypt_string` per-value encryption. Master password in `.vault_pass` (gitignored, never in KB). |
| Wildcard DNS | Single dnsmasq record `*.haytham.internal → 192.168.100.12` (NPM). New services need no DNS change. |
| Wildcard cert | Self-signed `*.haytham.internal`, imported to NPM. CA must be trusted per device. |
| Ephemeral storage | Default: all data lives inside LXC rootfs. `terraform destroy` = data loss. See `architecture/persistence-design.md`. |
| Reproducibility | Property validated by full build with `failed=0` and identical verification output. |
