#!/bin/bash
set -eo pipefail

# Require TPM2
if [ ! -c /dev/tpm0 ]; then
  echo "ERROR: No TPM2 device at /dev/tpm0 — aborting"
  echo "ERROR: All OVH EPYC servers should have fTPM. Check BIOS settings."
  exit 1
fi

# Find the device behind /encrypted (mounted or via fstab)
DEVICE=$(findmnt -n -o SOURCE /encrypted 2>/dev/null || true)
if [ -z "$DEVICE" ]; then
  DEVICE=$(awk '$2 == "/encrypted" {print $1}' /etc/fstab)
fi

if [ -z "$DEVICE" ]; then
  echo "ERROR: Cannot find device for /encrypted"
  exit 1
fi

# Already set up — skip
if [ "$DEVICE" = "/dev/mapper/encrypted" ]; then
  echo "INFO: /encrypted is already mounted from /dev/mapper/encrypted — skipping setup"
  exit 0
fi

# Already LUKS — ensure mounted, then skip
if cryptsetup isLuks "$DEVICE" 2>/dev/null; then
  echo "INFO: $DEVICE is already LUKS — skipping setup"
  if ! findmnt -n /encrypted >/dev/null 2>&1; then
    cryptsetup open "$DEVICE" encrypted --type luks2 || true
    mount /dev/mapper/encrypted /encrypted
  fi
  exit 0
fi

# Unmount placeholder ext4
umount /encrypted 2>/dev/null || true

# LUKS2 format with temporary passphrase
PASSPHRASE=$(head -c 32 /dev/urandom | base64)

echo -n "$PASSPHRASE" | cryptsetup luksFormat --type luks2 \
  --pbkdf argon2id \
  --batch-mode "$DEVICE" -

echo -n "$PASSPHRASE" | cryptsetup open --type luks2 "$DEVICE" encrypted -

# Enroll TPM2 so unlock is automatic on boot
# PCR 7  = Secure Boot policy (static baseline)
# PCR 11 = UKI kernel hash (systemd-stub measurement) — detects kernel/initrd tampering
# PCR 14 = pigeon-verify binary integrity (initrd measures critical binaries before LUKS)
echo -n "$PASSPHRASE" | systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs="7+11+14" \
  "$DEVICE"

# Remove passphrase slot — TPM2 is the only unlock method
echo -n "$PASSPHRASE" | cryptsetup luksRemoveKey "$DEVICE" -

mkfs.ext4 -L encrypted /dev/mapper/encrypted
mount /dev/mapper/encrypted /encrypted

# Replace fstab placeholder with crypttab + dm entry
sed -i '\|/encrypted|d' /etc/fstab

# Prefer stable by-id path for crypttab
DEVICE_ID=$(find /dev/disk/by-id/ -lname "*/${DEVICE##*/}" | grep -v wwn- | head -1 || true)
DEVICE_REF="${DEVICE_ID:-$DEVICE}"

echo "encrypted $DEVICE_REF - tpm2-device=auto" >> /etc/crypttab
echo "/dev/mapper/encrypted /encrypted ext4 defaults 0 2" >> /etc/fstab

# Include LUKS/TPM unlock in initramfs
update-initramfs -u
