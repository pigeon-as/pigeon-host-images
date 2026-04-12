# Agent Instructions

## Project Overview

Packer-built OVH BYOLinux images for pigeon dedicated servers. Two images (control-plane, worker) with per-concern install scripts. Images are secret-free — secrets are derived on-host by pigeon-enroll, configs rendered by pigeon-template.

## Critical Rule: Align with OVH BYOLinux Reference

The `setup-kernel.sh` and `make-image-bootable.sh` scripts are adapted from [ovh/bringyourownlinux](https://github.com/ovh/bringyourownlinux). Cross-check the reference when modifying these scripts.

## Architecture

```
control-plane.pkr.hcl           Packer QEMU: Ubuntu 24.04 cloud → server qcow2
worker.pkr.hcl                  Packer QEMU: Ubuntu 24.04 cloud → worker qcow2
cloud-init/                     Build-time cloud-init (root SSH for Packer)
  user-data                     Sets root password
  meta-data                     Instance metadata
templates/                      Static configs (file provisioner → final paths)
  vault.service                 ConditionFileNotEmpty=/etc/vault.d/vault.hcl
  consul.service                ConditionFileNotEmpty=/etc/consul.d/consul.hcl
  nomad.service                 ConditionFileNotEmpty=/etc/nomad.d/nomad.hcl
  pigeon-mesh.service           ConditionPathExists=/etc/pigeon/mesh.json
  pigeon-fence.service          After=network-online.target, single --config (fence.hcl), gated on enroll.json
  pigeon-enroll.service         ConditionPathExists=/etc/pigeon/enrollment-key + ExecStartPost render (control-plane only)
  pigeon-enroll-actions.service One-time post-claim actions (control-plane only)
  pigeon-template.service       setup-worker.sh rendering only (control-plane only)
  template-server.hcl           pigeon-template HCL config → /etc/pigeon/template.hcl (control-plane, setup-worker only)
  render-server.hcl             pigeon-enroll render config → /etc/pigeon/render.hcl (control-plane)
  render.hcl                    pigeon-enroll render config → /etc/pigeon/render.hcl (worker)
  fence-server.hcl              pigeon-fence base rules → /etc/pigeon/fence.hcl (control-plane)
  fence-worker.hcl              pigeon-fence base rules → /etc/pigeon/fence.hcl (worker)
  cmdline                       UKI base kernel cmdline → /etc/kernel/cmdline (CIS hardening + rd.shell=0 + console)
  nftables.conf                 Boot safety net (policy accept + ct state invalid drop)
  sysctl.conf                   Kernel + network tuning → /etc/sysctl.d/99-pigeon.conf
  limits.conf                   File descriptor limits → /etc/security/limits.d/99-pigeon.conf
  kvm.conf                      KVM timer tuning → /etc/modprobe.d/kvm.conf (worker only)
  sysupdate.d/
    50-usr.transfer             systemd-sysupdate: A/B usr.img download config
    70-uki.transfer             systemd-sysupdate: A/B UKI download config (boot counting)
scripts/
  setup-kernel.sh               Purge cloud kernel, install generic kernel, microcode, dracut-core, squashfs-tools, ukify, systemd-boot, btrfs-progs
  setup-apt-sources.sh          HashiCorp apt repository
  setup-encryption.sh           apt install cryptsetup + tpm2-tools (LUKS + veritysetup)
  setup-nftables.sh             apt install nftables
  setup-pigeon-mesh.sh          pigeon-mesh binary download ($PIGEON_MESH_VERSION)
  setup-pigeon-enroll.sh        pigeon-enroll binary download ($PIGEON_ENROLL_VERSION)
  setup-pigeon-template.sh      pigeon-template binary download ($PIGEON_TEMPLATE_VERSION)
  setup-pigeon-fence.sh         pigeon-fence binary download ($PIGEON_FENCE_VERSION)
  setup-pigeon-provisioner.sh   pigeon-provisioner binary download ($PIGEON_PROVISIONER_VERSION, control-plane only)
  setup-vault.sh                apt install vault ($VAULT_VERSION), profile env vars
  setup-consul.sh               apt install consul ($CONSUL_VERSION), profile env vars
  setup-nomad.sh                apt install nomad ($NOMAD_VERSION), plugins dir, profile env vars
  setup-firecracker.sh          Firecracker + jailer binaries ($FIRECRACKER_VERSION), checksum verified
  setup-cni.sh                  CNI plugins ($CNI_VERSION), checksum verified
  setup-driver.sh               nomad-driver-firecracker plugin ($DRIVER_VERSION)
  setup-lvm-plugin.sh           nomad-plugin-lvm plugin ($LVM_PLUGIN_VERSION)
  setup-bird.sh                 BIRD2 (apt)
  setup-haproxy.sh              HAProxy (apt)
  consul-acl-bootstrap.sh       One-time Consul ACL bootstrap → /usr/local/bin/ (control-plane only)
  nomad-acl-bootstrap.sh        One-time Nomad ACL bootstrap → /usr/local/bin/ (control-plane only)
  setup-hugepages.sh            Hugetlbfs mount for Firecracker VMs (worker only)
  seal-rootfs.sh                Build-time: mksquashfs /usr + veritysetup + dracut (pcrphase) + ukify versioned UKI ($IMAGE_VERSION)
  setup-ovh.sh                  Prepare OVH BYOLinux hook directory
  cleanup.sh                    cloud-init reset, SSH keys, apt clean, machine-id
  make-image-bootable.sh        OVH deploy-time: LUKS format md1, btrfs, TPM2 enroll, populate root, install systemd-boot + versioned UKI to ESP
```

## What each image contains

### control-plane.qcow2

Vault server, Consul server, Nomad server+client, pigeon-mesh, pigeon-fence, pigeon-enroll (server + run-actions), pigeon-template, pigeon-provisioner (org namespace provisioning), ACL bootstrap scripts (Consul + Nomad), nftables, sysctl tuning, FD limits.

### worker.qcow2

Consul client, Nomad client, pigeon-mesh, pigeon-fence, pigeon-enroll (claim + render CLI), nftables, Firecracker, jailer, CNI plugins, nomad-driver-firecracker, nomad-plugin-lvm, BIRD2, HAProxy, sysctl tuning, FD limits, KVM tuning, hugepages mount. pigeon-cni is a Nomad artifact job (not baked in).

## Design Principles

1. **Secret-free images** — all binaries, users, directories, systemd units, and pigeon-template configs are baked in. Zero secrets. Services are gated by `ConditionFileNotEmpty` or `ConditionPathExists` until pigeon-template renders their configs.
2. **Immutable /usr (Pure Lennart Model)** — `/usr` is a read-only squashfs mounted via dm-verity. No apt, no package writes, no runtime modification. Security patches = new image build + rolling deploy (Talos/Bottlerocket model).
3. **A/B updates via systemd-sysupdate** — versioned artifacts (`usr_<version>.img` + `pigeon_<version>.efi`) with `InstancesMax=2`. systemd-boot handles boot counting (3 tries) and automatic fallback. `boot-complete.target` gates bless-boot.
4. **btrfs root** — LUKS2 root partition uses btrfs for per-block checksumming, zstd compression, and future snapshot capability. Lennart's recommendation for the writable partition.
5. **systemd-pcrphase** — boot phase measurements extend PCR 11 at phase boundaries. UKI signed for `enter-initrd` phase only — LUKS can only unseal during initrd, not from a running system.
6. **Per-concern scripts** — one script per component. Scripts only install; configs are separate static files.
7. **Named version env vars** — each versioned install reads its own env var (e.g. `$FIRECRACKER_VERSION`), set inline in the Packer `environment_vars` block. No indirection through Packer variables.
8. **File provisioners for configs** — systemd units, nftables rules, and pigeon-template HCL configs are static files in `templates/`, provisioned directly to their final paths.
9. **Profile lines in install scripts** — each HashiCorp install script appends env vars to `/etc/profile.d/pigeon.sh`. No completions (dedicated servers, not interactive).
10. **HashiCorp apt repo** — Vault, Consul, Nomad installed via apt (handles binary + user + dirs). Systemd units overridden via file provisioner.
11. **OVH BYOLinux** — images deployed via `os = "byolinux_64"` with software RAID + cloud-init ConfigDrive.
12. **Standard FHS paths** — configs at `/etc/<service>.d/`, certs at `/etc/<service>.d/certs/`, pigeon at `/etc/pigeon/`, runtime state at `/var/lib/pigeon/`. Follows official HashiCorp deployment guides.

## Fence Config Architecture

pigeon-fence loads a single static config file per role:

- **`/etc/pigeon/fence.hcl`** — static rules baked by Packer (no secrets, no OVH API). Contains the nftables provider, overlay accept, ICMP, WireGuard inbound, memberlist inbound, SSH inbound (wg0 only), outbound rules, and worker-specific rules (BGP, BFD, HTTP/HTTPS inbound, forward).

No OVH API dependency — WireGuard and memberlist are crypto-authenticated protocols safe to expose to any source. SSH is restricted via `inbound_interface = "wg0"` (strictly stronger than IP-based filtering — requires overlay mesh membership).

Security properties:
- **Crypto-authenticated ports** — WireGuard (Noise protocol, can't handshake without peer key) and memberlist (AES-256 gossip encryption, can't join without key) are open from any source. Designed to be internet-facing.
- **SSH via overlay only** — `inbound_interface = "wg0"` restricts SSH to the private WireGuard mesh. No public SSH, no IP allowlist needed.
- **Pre-enroll safety** — pigeon-fence gated on `ConditionPathExists=/var/lib/pigeon/enroll.json`. Before enrollment, boot-time nftables.conf (policy accept) allows initial Terraform SSH. After enrollment, pigeon-fence activates (policy drop + specific rules).
- **No OVH credentials needed** — eliminates OVH API dependency, OVH credentials in enrollment, template rendering for fence, and the fence.d directory.

## Packer Build Flow

1. `setup-kernel.sh` — purge cloud kernel, install generic kernel, microcode, dracut-core, squashfs-tools, ukify, systemd-boot, btrfs-progs
2. Install scripts — all in one provisioner with `scripts` + `environment_vars`
3. File provisioners — systemd units, nftables, sysctl, limits, kvm, pigeon-template HCL configs, sysupdate.d transfer configs
4. Enable pigeon services — shell provisioner after file provisioners (service files must exist first)
5. Hugepages mount — `setup-hugepages.sh` (worker only)
6. `seal-rootfs.sh` — mksquashfs /usr → veritysetup → dracut initrd (pcrphase) → ukify versioned UKI (immutable /usr sealed)
7. OVH boot hook — `setup-ovh.sh` + file provisioner for `make-image-bootable.sh`
8. `cleanup.sh` — daemon-reload, cloud-init clean, remove caches

## Image → Boot → Config Flow

### Control-plane

1. **Build time** (Packer): Install all software, enable services, bake sysupdate.d transfer configs, seal /usr (squashfs + dm-verity + versioned UKI w/ pcrphase), bake pigeon-template config + make_image_bootable.sh
2. **Deploy time** (OVH): Partition disks (RAID: md0 ESP + md1 LUKS root + md2 staging), rsync image to md2, run make_image_bootable.sh chrooted (LUKS format md1 as btrfs + TPM2 PolicyAuthorize enroll + populate root + install systemd-boot + versioned UKI to ESP), reboot via iPXE → systemd-boot → UKI
3. **Boot** (systemd-boot → UKI → dracut): systemd-boot picks highest-version UKI → systemd-stub measures into PCR 11 → systemd-pcrphase extends PCR 11 (`enter-initrd`) → systemd-cryptsetup unseals LUKS via PolicyAuthorize → mount btrfs root → systemd-veritysetup mounts immutable /usr from dm-verity → switch_root → pcrphase extends (`leave-initrd`, `sysinit`, `ready`)
4. **First boot** (cloud-init): Read ConfigDrive for hostname + SSH key
5. **Provisioning** (Terraform SSH): Deliver enrollment-key + enroll-server.hcl to /etc/pigeon/ → pigeon-enroll starts
6. **Secret derivation** (pigeon-enroll): HKDF from enrollment key → writes /var/lib/pigeon/enroll.json
7. **Config rendering** (pigeon-template): Watches enroll.json → renders mesh.json, consul.hcl, vault.hcl, nomad.hcl
8. **Services start**: pigeon-mesh → pigeon-fence, vault, consul, nomad (ConditionFileNotEmpty gates)
9. **Boot blessing** (systemd-bless-boot): All services healthy → boot-complete.target → UKI marked as good

### Worker

1. **Build time** (Packer): Install all software, enable services, bake sysupdate.d transfer configs, seal /usr (squashfs + dm-verity + versioned UKI w/ pcrphase), bake .tpl templates + render.hcl + make_image_bootable.sh
2. **Deploy time** (OVH): Partition disks (RAID: md0 ESP + md1 LUKS root + md2 staging), rsync image to md2, run make_image_bootable.sh chrooted (LUKS format md1 as btrfs + TPM2 PolicyAuthorize enroll + populate root + install systemd-boot + versioned UKI to ESP), reboot via iPXE → systemd-boot → UKI
3. **Boot** (systemd-boot → UKI → dracut): systemd-boot picks highest-version UKI → systemd-stub measures into PCR 11 → systemd-pcrphase extends PCR 11 (`enter-initrd`) → systemd-cryptsetup unseals LUKS via PolicyAuthorize → mount btrfs root → systemd-veritysetup mounts immutable /usr from dm-verity → switch_root → pcrphase extends (`leave-initrd`, `sysinit`, `ready`)
4. **First boot** (cloud-init): Read ConfigDrive for hostname + SSH key + user_data
5. **Enrollment + rendering** (user_data — setup-worker.sh.tpl): pigeon-enroll claim (fetch secrets → write enroll.json) → pigeon-enroll render (HCL templates → mesh.json, consul.hcl, nomad.hcl)
6. **Services start**: pigeon-mesh → pigeon-fence, consul, nomad (ConditionFileNotEmpty gates)
7. **Boot blessing** (systemd-bless-boot): All services healthy → boot-complete.target → UKI marked as good

## Build & Test

```bash
make init       # Download Packer plugins
make build      # Build both images
make validate   # Packer validate
make clean      # Remove output/
```

Requires: packer, qemu-system-x86, qemu-utils.

## Release

Tag push (`v*`) triggers GitHub Actions → builds both images → extracts sysupdate artifacts → uploads all to GitHub Release.

Build outputs per image:
- `control-plane.qcow2` / `worker.qcow2` — OVH BYOLinux deployment image
- `pigeon_VERSION.usr.img` — squashfs + dm-verity (systemd-sysupdate A/B update)
- `pigeon_VERSION.efi` — UKI with PCR signing (systemd-sysupdate A/B update)

The sysupdate artifacts are extracted from inside the Packer VM via `file` provisioner (`direction = "download"`) after `seal-rootfs.sh` runs. Same artifacts, same build — no separate extraction pipeline.

`updates.pigeon.as` serves the sysupdate artifacts for `systemd-sysupdate` (flat URL, `Type=url-file`). Hosting TBD (Cloudflare R2 or Caddy rewrite proxy to GitHub Releases, per Flatcar sysext-bakery pattern).

```
https://github.com/pigeon-as/pigeon-host-images/releases/download/v0.1.0/control-plane.qcow2
https://github.com/pigeon-as/pigeon-host-images/releases/download/v0.1.0/worker.qcow2
https://github.com/pigeon-as/pigeon-host-images/releases/download/v0.1.0/pigeon_0.1.0.usr.img
https://github.com/pigeon-as/pigeon-host-images/releases/download/v0.1.0/pigeon_0.1.0.efi
```
