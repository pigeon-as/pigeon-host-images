# pigeon-host-images

Host images for pigeon servers.

Two images: **[control-plane.qcow2](control-plane.pkr.hcl)** and **[worker.qcow2](worker.pkr.hcl)**.

## Measured Boot

UKI (Unified Kernel Image) with UEFI iPXE direct boot. LUKS sealed to TPM2 PCR 7 (firmware/Secure Boot) + PCR 11 (`systemd-stub` extends with UKI kernel/initrd hash). Kernel updates without rebuilding the image change PCR 11 and lock out the volume — blacklisted from unattended-upgrades.

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