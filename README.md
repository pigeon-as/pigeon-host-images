# pigeon-host-images

Host images for pigeon servers.

Two images: **[control-plane.qcow2](control-plane.pkr.hcl)** and **[worker.qcow2](worker.pkr.hcl)**.

## Build

```bash
make build      # Build both images
make validate   # Packer validate only
make clean      # Remove output/
```

Requires: `packer`, `qemu-system-x86`, `qemu-utils`.

Versions are set inline in the HCL `environment_vars` blocks; edit the HCL files to pin versions.