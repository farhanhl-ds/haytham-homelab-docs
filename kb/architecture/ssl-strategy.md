---
id: arch-ssl-strategy
title: SSL TLS Strategy
tier: "x"
ctid: "n/a"
ip: n/a
status: planned
last_verified: unreleased
tags: [architecture, ssl, npm]
retrievable: true
---

# SSL/TLS Strategy

## 1. Approach

One wildcard self-signed `*.haytham.internal`, imported to NPM, root CA trusted per device.

```ini
[dn]
CN = *.haytham.internal

[alt_names]
DNS.1 = *.haytham.internal
DNS.2 = haytham.internal
```

Attach the same certificate to every NPM Proxy Host with Force SSL + HTTP/2.

## 2. Generation procedure (WSL)

```bash
mkdir -p ~/homelab-cert && cd ~/homelab-cert

cat > haytham-internal.cnf <<'EOF'
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = ext

[dn]
CN = *.haytham.internal

[ext]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = *.haytham.internal
DNS.2 = haytham.internal
EOF

openssl genrsa -out haytham-internal.key 2048
chmod 600 haytham-internal.key
openssl req -x509 -new -nodes -key haytham-internal.key -sha256 \
  -days 3650 -out haytham-internal.crt \
  -config haytham-internal.cnf -extensions ext

# verify, then back up to two places immediately (WSL is ephemeral):
openssl x509 -in haytham-internal.crt -noout -subject -ext subjectAltName -enddate
mkdir -p "/mnt/c/Users/<you>/Documents/homelab-cert-backup"
cp haytham-internal.key haytham-internal.crt haytham-internal.cnf \
  "/mnt/c/Users/<you>/Documents/homelab-cert-backup/"
```

Keep exactly three files (`.key`, `.crt`, `.cnf`). The `.cnf` makes regeneration reproducible — guard it like the key. Migrate all three to a Vaultwarden attachment once Vaultwarden is up; then remove loose copies.

No CSR file is produced or needed: the single `req -x509` command self-signs directly. A CSR is only useful when sending to an external CA.

## 3. Why not Let's Encrypt now

`.internal` cannot pass public ACME validation (nonexistent in public DNS).

## 4. Upgrade path (future)

Buy a public domain, serve `*.haytham.internal` internally and the public zone externally (split-horizon in Pi-hole), wildcard via DNS-01. Service prefix structure stays identical; only the base changes. Tracked in `roadmap/future-services.md`.

## 5. FAQ

**Q: Do I need a new cert per service?**
A: No — one wildcard covers all. Reuse it in NPM.

**Q: Browser warns on a new device?**
A: Install `haytham-internal.crt` to that device's trusted root store (`certmgr.msc` on Windows).
