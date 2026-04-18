# TLS — Stage 0 / Stage 1

Two stages. Stage 0 gets services running. Stage 1 replaces bootstrap certs with short-lived Vault PKI certs. The transition is automatic — vault-agent handles it.

## Stage 0 — Bootstrap CA

pigeon-enroll derives three CAs from the enrollment key via HKDF: `identity` (mTLS to the enroll server), `mesh` (pigeon-mesh overlay), `bootstrap` (stage-0 service leaves), and `vault` (Vault's own long-lived TLS). During the first ~60 seconds of boot, these CAs sign all service TLS certs:

| Cert | Signed by | TTL | Purpose |
|------|-----------|-----|---------|
| Vault server | Vault CA | 10 years | Vault's own TLS (permanent — never rotated by vault-agent) |
| Mesh server/worker | Mesh CA | 720h | Replaced at stage 1 |
| Consul server | Bootstrap CA | 720h | Replaced at stage 1 |
| Nomad server | Bootstrap CA | 720h | Replaced at stage 1 |
| Auth server/worker | Bootstrap CA | 720h | vault-agent replaces with 24h Vault PKI cert |

Leaf certs are issued by `pigeon-template-reconcile.service` running `pigeon-enroll issue pki/<role> -renew-before=1h` on a 30s tick — idempotent (no-op when the cert is valid for >1h), private keys never leave the host, deletion auto-heals on the next tick. Stage 0 ends when Terraform applies the platform stack (Vault PKI mounts + vault-agent config) and vault-agent overwrites the same paths with Vault-PKI-signed certs.

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
pigeon-enroll.service starts (TPM-sealed enrollment key via systemd-creds)
  → Terraform SSH register → /etc/pigeon/identity/{cert,key,ca}.pem
    (on subsequent boots when cert.pem is missing, pigeon-identity-ensure
     calls register without a token; the server recognises the EK binding)
  → pigeon-template.path fires on identity cert
  → pigeon-template-reconcile.service (long-running):
      · pigeon-enroll read template/enroll-server → /var/lib/pigeon/enroll.json
      · pigeon-enroll issue pki/{mesh,auth,vault,consul,nomad}_server -renew-before=1h (stage-0 leaves)
      · renders CA files, JWT pubkey, service configs
      · fires `systemctl start vault` / consul / nomad / unbound / pigeon-mesh / vault-agent as each config lands
  → pigeon-fence.path fires on enroll.json → starts pigeon-fence
  → vault-agent.path fires on stage-0 auth leaf → starts vault-agent
  → vault-init.service initializes Vault + management token
  → consul-acl-bootstrap.service registers Nomad agent token
  → Terraform platform stack (Vault PKI mounts, cert auth, policies)
  → vault-agent issues Vault-PKI certs + dual-CA bundles; consul/nomad reload
  → pigeon-mesh reloads mesh certs on next TLS handshake
```

### Worker

```
cloud-init user_data (setup-worker.sh rendered by control-plane reconcile):
  · hostnamectl, write /etc/pigeon/enroll.env, pigeon-enroll register (with token)
    (on subsequent boots with cert.pem missing, pigeon-identity-ensure
     re-registers without a token via TPM rebootstrap)
  → pigeon-template.path fires on identity cert
  → pigeon-template-reconcile.service: stage-0 leaves (mesh_worker + auth_worker),
    CAs, JWT (auto_config intro token), service configs
  → pigeon-fence.path fires on enroll.json → starts pigeon-fence
  → vault-agent.path fires on stage-0 auth leaf → starts vault-agent
  → nomad-cert.path fires once vault-agent issues the Vault-PKI nomad-client cert
  → luks-recovery.service adds the HKDF-derived LUKS recovery passphrase
  → pigeon-mesh reloads mesh certs on next TLS handshake
```

## Self-healing

All heal paths align with established reference projects: cert-manager (reconcile-based, heal-if-missing), step-ca (`--renew-before` / `needs-renewal` duration semantics), and SPIRE (`rebootstrap_mode=auto` — re-run the original TPM NodeAttestor, no operator token).

**What heals automatically:**

- **Service config deletion.** reconcile.service re-renders `vault.hcl`, `consul.hcl`, `nomad.hcl`, `mesh.json`, `unbound.conf`, `resolv.conf`, `vault-agent.env` continuously from the enroll bundle. Delete any of these files mid-life and they come back within the next reconcile tick, with the matching `systemctl start X` hook firing if the service had stopped.
- **CA file deletion.** Same — CA files (`mesh-ca.crt`, `bootstrap-ca.crt`, `vault.d/certs/ca.crt`, etc.) are re-rendered by reconcile from `pigeon-enroll read ca/*` exec sources.
- **enroll.json deletion.** reconcile's `refresh_enroll_json` exec source re-fetches the vars/secrets bundle from `pigeon-enroll read template/enroll-<role>` at a 1h interval (or faster if fsnotify detects deletion and pigeon-template refetches).
- **Stage-0 leaf cert deletion.** reconcile runs `pigeon-enroll issue pki/<role> -renew-before=1h` on a 30s tick for every stage-0 leaf. When the cert is valid for more than 1h the call is a silent no-op; when the cert is missing or near expiry it re-issues. After vault-agent has taken over, the issued stage-0 cert is immediately overwritten by vault-agent's next render — brief churn, self-corrects.
- **Identity cert deletion (SPIRE rebootstrap).** `pigeon-identity-ensure.service` runs on boot when `/etc/pigeon/identity/cert.pem` is missing and `ca.pem` indicates a prior registration. It calls `pigeon-enroll register` **without a token**; the server recognises the TPM EK from its binding store (EK→identity recorded at first register) and reissues on TPM credential-activation alone. No sealed backup, no operator action.
- **Stage-1 cert expiry.** vault-agent rotates at 50% lifetime (24h TTL → 12h renewal window). Service reloads on cert change via ctmpl `command` hooks.
- **Service crashes.** Each service has `Restart=on-failure`; systemd brings them back.
- **Reboots.** Everything rederivable from the enrollment key + the TPM. Stage-0 leaves are re-issued fresh by reconcile; identity is restored by pigeon-identity-ensure if missing; vault-agent rotates in stage-1 shortly after.

**What does NOT heal automatically:**

- **Whole `/etc/pigeon/identity/` deleted (including ca.pem).** `pigeon-identity-ensure` is gated by `ca.pem` existence; without it, `ENROLL_CACERT` can't be loaded. Operator runs Terraform (or re-runs cloud-init on workers) to re-deliver the identity CA and kick off a normal register.
- **Loss of the enrollment key itself.** Catastrophic and intentional — this is the root trust. Re-run `terraform apply` to redeliver the same key from Terraform state; all HKDF-derived CAs remain valid.
- **Binding store lost on the enroll server.** The server would require a fresh HMAC token for rebootstrap until bindings re-accumulate. Back up `/var/lib/pigeon/enroll-bindings` with the rest of the control-plane state.
- **Vault permanently broken.** Stage-0 leaves expire at 30 days. Beyond that, services fail TLS and the cluster degrades.
