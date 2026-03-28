# pigeon-host-images

Host images for pigeon servers.

Two images: **[control-plane.qcow2](control-plane.pkr.hcl)** and **[worker.qcow2](worker.pkr.hcl)**.

## Build

```bash
make build      # Build both images
make validate   # Packer validate only
make clean      # Remove build/
```

Requires: `packer`, `qemu-system-x86`, `qemu-utils`.

Versions are set inline in the HCL `environment_vars` blocks; edit the HCL files to pin versions.

## Measured Boot

Images use UKI (Unified Kernel Image) with iPXE direct boot — no GRUB in the chain. LUKS is sealed to TPM2 PCR 7+11: PCR 7 covers firmware/Secure Boot config, PCR 11 is extended by `systemd-stub` with the UKI kernel/initrd hash. This means a kernel update without rebuilding the image will change PCR 11 and lock out the LUKS volume — kernel updates are blacklisted from unattended-upgrades for this reason.