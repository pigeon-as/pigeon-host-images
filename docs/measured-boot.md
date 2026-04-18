# Measured Boot — Signed PCR Policy + dm-verity

Pure Lennart Model: hermetic /usr (immutable squashfs + dm-verity) + encrypted writable root (LUKS2 + TPM2 PolicyAuthorize). Zero custom boot code.

## Trust Chain

```
squashfs (/usr) → veritysetup → root hash → UKI cmdline → PCR 11 → signed policy → LUKS unseal
```

## Boot Chain

```
firmware → iPXE → UKI → dracut initrd
  → systemd-cryptsetup (TPM2 PolicyAuthorize) → mount LUKS root
  → systemd-veritysetup (usr.img → loop → dm-verity) → mount /usr (squashfs, immutable)
  → switch_root
```

## Disk Layout

| Array | Content | Size | Purpose |
|-------|---------|------|---------|
| md0 | ESP (FAT32) | 1 GiB | UKI (pigeon.efi) |
| md1 | LUKS2 root (btrfs) | ~20 GiB | Writable /etc + /var + /opt + usr.img |
| md2 | OVH staging | remainder | Dead after first boot |

## How It Works

1. **Build time** (`scripts/build-uki.sh`): `mksquashfs /usr` → `veritysetup format` (hash-offset pattern) → `dracut` (systemd initrd) → `ukify build` (kernel + initrd + cmdline with `usrhash=<hash>`, PCR 11 signed)
2. **Deploy time** (`make-image-bootable.sh`): LUKS format md1 → `systemd-cryptenroll --tpm2-public-key` (PolicyAuthorize) → populate root → install UKI to ESP
3. **Boot**: systemd-stub extends PCR 11 → systemd-cryptsetup verifies `.pcrsig` signature → LUKS unseals → root mounts → veritysetup mounts /usr via dm-verity

## Security Properties

- **Immutable /usr** — read-only squashfs, dm-verity protected. Any modification → kernel panic.
- **Encrypted root** — LUKS2 with TPM2 PolicyAuthorize. OVH rescue mode / disk pull → TPM refuses → secrets unreadable.
- **Signed PCR policy** — UKI replacement not signed with our key → wrong PCR signature → LUKS stays sealed → server is a brick.
- **No Secure Boot** — OVH has no Secure Boot API. UKI is unsigned for firmware. Security relies on TPM2 PolicyAuthorize (PCR 11) + dm-verity.
- **TOFU** — first boot is trusted (fresh OVH hardware). After TPM enrollment, integrity is enforced.

## Updating / Patching

Security patches = new image build + rolling deploy (Talos/Bottlerocket model):

1. Rebuild image in Packer (new squashfs → new verity hash → new UKI)
2. Re-sign UKI with same RSA-2048 key (`ukify --pcr-private-key`)
3. Rolling deploy via OVH reinstall
4. No `systemd-cryptenroll` needed on nodes (PolicyAuthorize validates the signature, not a literal PCR value)

Key rotation (rare): `systemd-cryptenroll --tpm2-public-key=<new>` on each node.

## Recovery

If TPM2 fails to unseal (e.g., hardware failure):

```bash
# Use the HKDF-derived recovery passphrase added by luks-recovery.service
cryptsetup open /dev/md1 root
```

The recovery passphrase is derived from the enrollment key via HKDF and added to LUKS keyslot 1 by `luks-recovery.service` (`/usr/local/bin/luks-recovery`) after `pigeon-template-reconcile` has the identity cert in place.
