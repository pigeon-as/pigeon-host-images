#!/bin/bash
set -euo pipefail
# OVH BYOLinux post-deploy hook — runs chrooted on staging (md2).
# Formats LUKS root on md1, populates from staging, enrolls TPM2,
# installs systemd-boot + versioned UKI with boot counting.
# Ref: https://help.ovhcloud.com/csm/en-gb-dedicated-servers-bring-your-own-linux

export DEBIAN_FRONTEND=noninteractive

# Unmount OVH's placeholder ext4 on md1 so we can reformat as LUKS
mountpoint -q /luks 2>/dev/null && umount /luks

# mdadm.conf from live RAID state
if [ -f /usr/share/mdadm/mkconf ]; then
  rm -f /etc/mdadm/mdadm.conf /etc/mdadm.conf
  /usr/share/mdadm/mkconf force-generate
fi
systemd-machine-id-setup

# LUKS format md1 with throwaway passphrase (discarded after TPM enrollment)
LUKS_PASS=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 -w0)
echo -n "$LUKS_PASS" | cryptsetup luksFormat --type luks2 --pbkdf argon2id --batch-mode --key-file=- /dev/md1
echo -n "$LUKS_PASS" | cryptsetup open --type luks2 --key-file=- /dev/md1 root

# Create and populate root filesystem (btrfs for checksumming + compression)
mkfs.btrfs -L root /dev/mapper/root
mount /dev/mapper/root /mnt
rsync -aAX \
  --exclude='/usr' --exclude='/boot' \
  --exclude='/proc' --exclude='/sys' --exclude='/dev' --exclude='/run' --exclude='/tmp' \
  --exclude='/mnt' --exclude='/root/.ovh' \
  / /mnt/
mkdir -p /mnt/usr /mnt/boot/efi /mnt/proc /mnt/sys /mnt/dev /mnt/run /mnt/tmp /mnt/mnt

# Minimal fstab — root and /usr come from UKI cmdline, but ESP must be
# mounted persistently for sysupdate and boot counting/blessing.
ESP_DEV=$(findmnt -no SOURCE /boot/efi)
ESP_UUID=$(blkid -s UUID -o value "$ESP_DEV")
echo "UUID=${ESP_UUID} /boot/efi vfat umask=0077,noatime 0 2" > /mnt/etc/fstab

umount /mnt
cryptsetup close root

# Enroll TPM2 PolicyAuthorize — fail hard if prerequisites are missing
# (without TPM enrollment, LUKS passphrase is discarded and the node is unbootable)
if ! [ -c /dev/tpmrm0 ]; then
  echo "FATAL: no TPM device (/dev/tpmrm0) — cannot enroll LUKS unlock" >&2
  exit 1
fi
if ! [ -f /etc/pigeon/pcr-signing-pubkey.pem ]; then
  echo "FATAL: no PCR signing pubkey (/etc/pigeon/pcr-signing-pubkey.pem) — cannot enroll LUKS unlock" >&2
  exit 1
fi
echo -n "$LUKS_PASS" | systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-public-key=/etc/pigeon/pcr-signing-pubkey.pem \
  /dev/md1

# Remove throwaway passphrase keyslot
echo -n "$LUKS_PASS" | cryptsetup luksRemoveKey --batch-mode --key-file=- /dev/md1
unset LUKS_PASS

# Install systemd-boot to ESP (manual copy — bootctl needs efivarfs, unavailable in chroot)
mkdir -p /boot/efi/EFI/systemd /boot/efi/EFI/BOOT /boot/efi/EFI/Linux /boot/efi/loader
cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /boot/efi/EFI/systemd/systemd-bootx64.efi
cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
cat > /boot/efi/loader/loader.conf <<'EOF'
timeout 0
auto-entries 1
auto-firmware 0
console-mode keep
EOF

# Copy versioned UKI with boot counting (3 tries before fallback)
UKI=$(ls -v /boot/pigeon_*.efi 2>/dev/null | tail -1 || true)
if [ -z "${UKI}" ]; then
  echo "FATAL: no UKI found in /boot/pigeon_*.efi" >&2
  exit 1
fi
UKI_BASE=$(basename "${UKI}" .efi)
cp "${UKI}" "/boot/efi/EFI/Linux/${UKI_BASE}+3.efi"

rm -rf /root/.ovh/
