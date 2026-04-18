# TLS — Stage 0 / Stage 1

Two stages. Stage 0 gets services running. Stage 1 replaces bootstrap certs with short-lived Vault PKI certs. The transition is automatic — vault-agent handles it.

## Stage 0 — Bootstrap CA

pigeon-enroll derives a bootstrap CA from the enrollment key via HKDF. During the first ~60 seconds of boot, this CA signs all service TLS certs:

| Cert | Signed by | TTL | Purpose |
|------|-----------|-----|---------|
| Vault server | Bootstrap CA | 10 years | Vault's own TLS (permanent — never rotated by vault-agent) |
| Consul server | Bootstrap CA | 720h | Temporary — replaced by stage 1 |
| Nomad server | Bootstrap CA | 720h | Temporary — replaced by stage 1 |
| Auth server | Bootstrap CA | 720h | Temporary — vault-agent replaces with 24h Vault PKI cert |

Stage 0 ends when Terraform applies the platform stack (Vault PKI mounts + vault-agent config).

## Stage 1 — Vault PKI

Vault generates its own internal root CA (key never leaves Vault). Four intermediates sign service certs:

```
Vault PKI root (internal)
├── pki_auth    → auth certs (vault-agent cert-auth identity, self-renewal)
├── pki_mesh    → mesh-server certs, mesh-client certs (24h TTL)
├── pki_consul  → consul-server certs (24h TTL)
└── pki_nomad   → nomad-server certs (24h), nomad-client certs (24h)
```

vault-agent on every node:
- Authenticates to Vault via cert auth (bootstrap-CA-signed auth cert)
- Issues short-lived service certs from the appropriate PKI intermediate
- Renders CA bundles (Vault root CA + bootstrap CA) so services trust both old and new certs
- Reloads services on cert renewal (`consul reload`, `systemctl reload nomad`)

## What vault-agent manages

### Control-plane (vault-agent-server.hcl)

| Template | Destination | Reload |
|----------|-------------|--------|
| auth-server-cert.ctmpl | /etc/pigeon/certs/auth/cert.pem | (self-renewal) |
| auth-server-key.ctmpl | /etc/pigeon/certs/auth/key.pem | (self-renewal) |
| mesh-ca.ctmpl | /etc/pigeon/certs/mesh-ca.crt | — |
| mesh-server-cert.ctmpl | /etc/pigeon/certs/mesh-cert.pem | — |
| mesh-server-key.ctmpl | /etc/pigeon/certs/mesh-key.pem | — |
| consul-server-cert.ctmpl | /etc/consul.d/certs/cert.pem | consul reload |
| consul-server-key.ctmpl | /etc/consul.d/certs/key.pem | consul reload |
| consul-ca.ctmpl | /etc/consul.d/certs/ca.crt | consul reload |
| nomad-server-cert.ctmpl | /etc/nomad.d/certs/cert.pem | systemctl reload nomad |
| nomad-server-key.ctmpl | /etc/nomad.d/certs/key.pem | systemctl reload nomad |
| nomad-ca.ctmpl | /etc/nomad.d/certs/ca.crt | systemctl reload nomad |

### Worker (vault-agent.hcl)

| Template | Destination | Reload |
|----------|-------------|--------|
| auth-cert.ctmpl | /etc/pigeon/certs/auth/cert.pem | (self-renewal) |
| auth-key.ctmpl | /etc/pigeon/certs/auth/key.pem | (self-renewal) |
| mesh-ca.ctmpl | /etc/pigeon/certs/mesh-ca.crt | — |
| mesh-cert.ctmpl | /etc/pigeon/certs/mesh-cert.pem | — |
| mesh-key.ctmpl | /etc/pigeon/certs/mesh-key.pem | — |
| nomad-cert.ctmpl | /etc/nomad.d/certs/cert.pem | systemctl reload nomad |
| nomad-key.ctmpl | /etc/nomad.d/certs/key.pem | systemctl reload nomad |
| nomad-ca.ctmpl | /etc/nomad.d/certs/ca.crt | systemctl reload nomad |

## What vault-agent does NOT manage

- **Vault's own TLS cert** — stays bootstrap-CA-signed (10-year TTL). This follows the [Vault deployment guide](https://developer.hashicorp.com/vault/tutorials/day-one-raft/raft-deployment-guide): pre-provision Vault TLS from an external CA. Confirmed by [vault-k8s injector source](https://github.com/hashicorp/vault-k8s): `VaultConfig.CACert` is loaded once at startup, never reloaded.
- **Consul worker certs** — Consul auto_config handles worker cert issuance from servers automatically.

## CA bundles

Services need to trust both the bootstrap CA (for Vault's cert) and the Vault PKI root (for vault-agent-issued certs). The Consul/Nomad `.ctmpl` templates concatenate both:

```
{{ with secret "pki/cert/ca" }}{{ .Data.certificate }}{{ end }}
{{ file "/etc/pigeon/certs/bootstrap-ca.crt" }}
```

Mesh CA bundle concatenates the Vault root with the HKDF-derived mesh CA (used during bootstrap):

```
{{ with secret "pki/cert/ca" }}{{ .Data.certificate }}{{ end }}
{{ file "/etc/pigeon/certs/mesh-enroll-ca.crt" }}
```

## Why Vault's cert is permanent

Vault must be running for vault-agent to issue certs. If vault-agent managed Vault's own cert, you'd have a circular dependency: Vault needs a cert → vault-agent needs Vault → Vault needs a cert. The HVD solution: Vault's TLS comes from an external CA with a long TTL.

## Boot sequence

### Control-plane

```
pigeon-enroll derive → secrets + bootstrap certs on disk
  → Consul starts (bootstrap cert, mTLS)
  → Vault starts (bootstrap cert, HTTPS)
  → vault-init action (initialize + management token)
  → consul-acl-bootstrap.service (register Nomad agent token in Consul ACL via consul acl CLI)
  → Terraform platform stack (Vault PKI mounts, cert auth, policies)
  → vault-agent starts → issues Vault-PKI certs + CA bundles
  → Consul/Nomad reload (now using 24h Vault PKI certs)
  → pigeon-mesh reloads mesh certs on next TLS handshake
```

### Worker

```
pigeon-enroll claim → secrets + bootstrap certs on disk
  → Consul starts (auto_config gets cert from servers)
  → vault-agent starts → issues nomad-client cert + mesh cert + CA bundles
  → Nomad starts (nomad-cert.path triggers once cert appears)
  → pigeon-mesh reloads mesh certs on next TLS handshake
```
