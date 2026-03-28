#!/bin/bash
set -exo pipefail
# OVH BYOLinux post-deploy hook — runs chrooted on the target server.
# Ref: https://help.ovhcloud.com/csm/en-gb-dedicated-servers-bring-your-own-linux?id=kb_article_view&sysparm_article=KB0061612

export DEBIAN_FRONTEND=noninteractive

# Regenerate mdadm.conf for the server's RAID layout
if [ -f /usr/share/mdadm/mkconf ]; then
  rm -f /etc/mdadm/mdadm.conf /etc/mdadm.conf
  /usr/share/mdadm/mkconf force-generate
fi

# Generate unique machine ID (cloud-init cleared it during cleanup)
systemd-machine-id-setup

# Rebuild initramfs with mdadm + LUKS modules
update-initramfs -u

# Build UKI (Unified Kernel Image) for measured boot
# systemd-stub extends PCR 11 with the kernel image hash on boot.
# iPXE loads the UKI directly via efiBootloaderPath (no GRUB in boot chain).
VMLINUZ=$(ls /boot/vmlinuz-* | sort -V | tail -1)
INITRD=$(ls /boot/initrd.img-* | sort -V | tail -1)
mkdir -p /boot/efi/EFI/Linux
ukify build \
  --linux="$VMLINUZ" \
  --initrd="$INITRD" \
  --cmdline=@/etc/kernel/cmdline \
  --output=/boot/efi/EFI/Linux/pigeon.efi

# Remove OVH deployment artifacts
rm -rf /root/.ovh/
