#!/bin/bash -e
set -o pipefail

if [ ! -c /dev/tpm0 ]; then
  echo "ERROR: No TPM2 device at /dev/tpm0 — aborting"
  echo "ERROR: All OVH EPYC servers should have fTPM. Check BIOS settings."
  exit 1
fi

DEVICE=$(findmnt -n -o SOURCE /encrypted 2>/dev/null || true)
if [ -z "$DEVICE" ]; then
  # Not mounted — check fstab.
  DEVICE=$(awk '$2 == "/encrypted" {print $1}' /etc/fstab)
fi

if [ -z "$DEVICE" ]; then
  echo "ERROR: Cannot find device for /encrypted"
  exit 1
fi

if [ "$DEVICE" = "/dev/mapper/encrypted" ]; then
  echo "INFO: /encrypted is already mounted from /dev/mapper/encrypted — skipping setup"
  exit 0
fi

if cryptsetup isLuks "$DEVICE" 2>/dev/null; then
  echo "INFO: $DEVICE is already LUKS — skipping setup"
  # Ensure it's open and mounted.
  if ! findmnt -n /encrypted >/dev/null 2>&1; then
    cryptsetup open "$DEVICE" encrypted --type luks2 || true
    mount /dev/mapper/encrypted /encrypted
  fi
  exit 0
fi

umount /encrypted 2>/dev/null || true

PASSPHRASE=$(head -c 32 /dev/urandom | base64)

echo -n "$PASSPHRASE" | cryptsetup luksFormat --type luks2 \
  --pbkdf argon2id \
  --batch-mode "$DEVICE" -

echo -n "$PASSPHRASE" | cryptsetup open --type luks2 "$DEVICE" encrypted -

echo -n "$PASSPHRASE" | systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs=7 \
  "$DEVICE"

echo -n "$PASSPHRASE" | cryptsetup luksRemoveKey "$DEVICE" -

mkfs.ext4 -L encrypted /dev/mapper/encrypted
mount /dev/mapper/encrypted /encrypted

sed -i '\|/encrypted|d' /etc/fstab

DEVICE_ID=$(find /dev/disk/by-id/ -lname "*/${DEVICE##*/}" | grep -v wwn- | head -1)
DEVICE_REF="${DEVICE_ID:-$DEVICE}"

echo "encrypted $DEVICE_REF - tpm2-device=auto" >> /etc/crypttab
echo "/dev/mapper/encrypted /encrypted ext4 defaults 0 2" >> /etc/fstab

update-initramfs -u
