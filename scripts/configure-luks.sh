#!/bin/bash -ex
set -o pipefail
# First-boot LUKS setup for /encrypted partition.
#
# Baked into Packer images at /usr/local/bin/configure-luks.sh.
# Called by:
#   - Terraform SSH provisioner (control-plane servers)
#   - setup-worker.sh via ConfigDrive user_data (workers)
#
# Assumes OVH installer created /encrypted as ext4 on a RAID device.
# Requires TPM2 — aborts if /dev/tpm0 is missing.
#
# Flow:
#   1. Find the RAID device behind /encrypted
#   2. Unmount the placeholder ext4
#   3. LUKS2 format with a temporary passphrase
#   4. Enroll TPM2 (PCR 7), remove passphrase slot
#   5. Open + mkfs.ext4 + mount
#   6. Create service directories
#   7. Write /etc/crypttab entry
#   8. Update initramfs to include LUKS/TPM unlock

# Require TPM2.
if [ ! -c /dev/tpm0 ]; then
  echo "ERROR: No TPM2 device at /dev/tpm0 — aborting"
  echo "ERROR: All OVH EPYC servers should have fTPM. Check BIOS settings."
  exit 1
fi

# Idempotent: skip if already LUKS-formatted.
DEVICE=$(findmnt -n -o SOURCE /encrypted 2>/dev/null || true)
if [ -z "$DEVICE" ]; then
  # Not mounted — check fstab for the device.
  DEVICE=$(awk '$2 == "/encrypted" {print $1}' /etc/fstab)
fi

if [ -z "$DEVICE" ]; then
  echo "ERROR: Cannot find device for /encrypted"
  exit 1
fi

# If already LUKS, skip setup.
if cryptsetup isLuks "$DEVICE" 2>/dev/null; then
  echo "INFO: $DEVICE is already LUKS — skipping setup"
  # Ensure it's open and mounted.
  if ! findmnt -n /encrypted >/dev/null 2>&1; then
    cryptsetup open "$DEVICE" encrypted --type luks2 || true
    mount /dev/mapper/encrypted /encrypted
  fi
  exit 0
fi

# --- Step 1: Unmount placeholder ext4 ---
umount /encrypted 2>/dev/null || true

# --- Step 2: LUKS2 format with temporary passphrase ---
PASSPHRASE=$(head -c 32 /dev/urandom | base64)

echo -n "$PASSPHRASE" | cryptsetup luksFormat --type luks2 \
  --pbkdf argon2id \
  --batch-mode "$DEVICE" -

# --- Step 3: Open + enroll TPM2 + remove passphrase ---
echo -n "$PASSPHRASE" | cryptsetup open --type luks2 "$DEVICE" encrypted -

echo "INFO: Enrolling TPM2 with PCR 7"
echo -n "$PASSPHRASE" | systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs=7 \
  "$DEVICE"

# Remove the passphrase slot — TPM is the only unlock method.
echo -n "$PASSPHRASE" | cryptsetup luksRemoveKey "$DEVICE" -
PASSPHRASE=""

# --- Step 4: Create filesystem + mount ---
mkfs.ext4 -L encrypted /dev/mapper/encrypted
mount /dev/mapper/encrypted /encrypted

# --- Step 5: Create service directories ---
mkdir -p /encrypted/consul/data
mkdir -p /encrypted/vault/data
mkdir -p /encrypted/nomad/data
mkdir -p /encrypted/pigeon

# Consul/Vault run as their own users (created by apt packages).
chown consul:consul /encrypted/consul /encrypted/consul/data 2>/dev/null || true
chown vault:vault /encrypted/vault /encrypted/vault/data 2>/dev/null || true

# --- Step 5b: Generate self-signed TLS cert ---
# Used by Vault, Consul, Nomad, pigeon-enroll for internal TLS.
# All internal traffic is already encrypted by WireGuard — this is defense-in-depth.
mkdir -p /encrypted/tls
if [ ! -f /encrypted/tls/server.key ]; then
  HOSTNAME=$(hostname)
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
    -keyout /encrypted/tls/server.key \
    -out /encrypted/tls/server.crt \
    -days 3650 -nodes \
    -subj "/CN=${HOSTNAME}" \
    -addext "subjectAltName=DNS:${HOSTNAME},DNS:localhost,IP:127.0.0.1"
  chmod 640 /encrypted/tls/server.key /encrypted/tls/server.crt
  # Vault needs to read the key.
  chown root:vault /encrypted/tls/server.key 2>/dev/null || true
  echo "INFO: Generated self-signed TLS cert for ${HOSTNAME}"
fi

# --- Step 6: /etc/crypttab ---
# Remove OVH's fstab entry for the placeholder ext4.
sed -i '\|/encrypted|d' /etc/fstab

# Resolve device to a stable by-id path for crypttab.
DEVICE_ID=$(find /dev/disk/by-id/ -lname "*/${DEVICE##*/}" | grep -v wwn- | head -1)
DEVICE_REF="${DEVICE_ID:-$DEVICE}"

echo "encrypted $DEVICE_REF - tpm2-device=auto" >> /etc/crypttab

# Add fstab entry for the decrypted mapper device.
echo "/dev/mapper/encrypted /encrypted ext4 defaults 0 2" >> /etc/fstab

# --- Step 7: Update initramfs ---
update-initramfs -u

echo "INFO: /encrypted LUKS setup complete"
