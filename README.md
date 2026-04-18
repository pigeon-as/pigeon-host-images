# pigeon-host-images

Host images for pigeon servers.

Two images: **[control-plane.qcow2](control-plane.pkr.hcl)** and **[worker.qcow2](worker.pkr.hcl)**.

## Measured Boot

UKI + LUKS sealed to TPM2 PolicyAuthorize (PCR 11). Immutable /usr via dm-verity on squashfs. Tampered /usr → kernel panic. Unsigned UKI → LUKS stays sealed → brick. See [docs/measured-boot.md](docs/measured-boot.md).

## TPM Attestation

Workers present TPM EK to pigeon-enroll before receiving secrets. EK validated against manufacturer CA certs or hash allowlist.

## TLS — Stage 0 / Stage 1

All service TLS is automatic and self-healing. Bootstrap CA handles initial boot; Vault PKI takes over once the platform stack is applied. vault-agent on every node issues 24h certs from four PKI intermediates (auth, mesh, consul, nomad) and reloads services on renewal.

## DNS

Unbound on every node: local recursive resolver, authoritative infra zone (rendered from mesh peers), `.internal` stub forwarding to Consul DNS.

## Build

```bash
make build      # Build both images
make validate   # Packer validate only
make clean      # Remove build/
```

Requires: `packer`, `qemu-system-x86`, `qemu-utils`.

Versions are set inline in the HCL `environment_vars` blocks; edit the HCL files to pin versions.