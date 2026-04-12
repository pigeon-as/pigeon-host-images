# pigeon-host-images

Host images for pigeon servers.

Two images: **[control-plane.qcow2](control-plane.pkr.hcl)** and **[worker.qcow2](worker.pkr.hcl)**.

## Measured Boot

UKI + LUKS sealed to TPM2 PolicyAuthorize (PCR 11). Immutable /usr via dm-verity on squashfs. Tampered /usr → kernel panic. Unsigned UKI → LUKS stays sealed → brick. See [docs/measured-boot.md](docs/measured-boot.md).

## TPM Attestation

Workers present TPM EK to pigeon-enroll before receiving secrets. EK validated against manufacturer CA certs or hash allowlist (SPIRE pattern).

## Build

```bash
make build      # Build both images
make validate   # Packer validate only
make clean      # Remove build/
```

Requires: `packer`, `qemu-system-x86`, `qemu-utils`.

Versions are set inline in the HCL `environment_vars` blocks; edit the HCL files to pin versions.