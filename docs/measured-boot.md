# Measured Boot (PCR 14)

Initramfs hashes critical binaries into TPM PCR 14 before LUKS unseals `/encrypted`. Tampered binary = brick.

## What's measured

All binaries in `scripts/pigeon-verify`. Add new binaries there when adding new setup scripts.

## Hot-patching a binary (rare — prefer server replacement)

```bash
# 1. Patch the binary
cp /tmp/new-consul /usr/bin/consul

# 2. Re-seal LUKS to new PCR values
systemd-cryptenroll --wipe-slot=tpm2 --tpm2-pcrs=7+11+14 /dev/md2

# 3. Reboot to verify
reboot
```

You'll need a recovery passphrase (pigeon-enroll `luks-recovery` action) to authenticate `systemd-cryptenroll`.
