#!/bin/bash
set -eo pipefail

export DEBIAN_FRONTEND=noninteractive

# Remove cloud GRUB settings (cloud image GRUB is only used during Packer build)
rm -f /etc/default/grub.d/50-cloudimg-settings.cfg
apt-get update

# Replace cloud kernel with generic
apt-get purge -y linux-virtual 'linux-image-*' 'linux-headers-*'
apt-get install -y linux-image-generic linux-headers-generic

# Bare metal packages
apt-get install -y mdadm lvm2 amd64-microcode intel-microcode curl jq

# UKI (Unified Kernel Image) for measured boot — systemd-stub extends PCR 11
# systemd-boot provides bootctl + EFI bootloader (boot counting, version sorting)
# dracut-core generates the systemd-based initrd (veritysetup + cryptsetup generators)
# squashfs-tools creates the immutable /usr squashfs image
# btrfs-progs provides mkfs.btrfs for the LUKS root filesystem
apt-get install -y systemd-ukify systemd-boot dracut-core squashfs-tools btrfs-progs

# Prevent cloud-init from reinstalling cloud GRUB or resizing partitions
sed -Ei '/^\s*-\s*(grub-dpkg|growpart|resizefs)/d' /etc/cloud/cloud.cfg

apt-get -y dist-upgrade
