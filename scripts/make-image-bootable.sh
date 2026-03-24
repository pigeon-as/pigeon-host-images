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

# Install GRUB for the server's boot mode
if [ -d /sys/firmware/efi ]; then
  echo "INFO: Installing GRUB for UEFI boot"
  apt-get -y install --no-install-recommends grub-efi-amd64
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --no-nvram
  apt-get -y purge grub-pc-bin 2>/dev/null || true
else
  echo "INFO: Installing GRUB for legacy boot"
  # Find physical disks behind boot partition (handles software RAID)
  read -r bootDevice _ < <(findmnt -A -c -e -l -n -T /boot/ -o SOURCE,FSTYPE)
  realBootDevices="$(lsblk -n -p -b -l -o TYPE,NAME "$bootDevice" -s | awk '$1 == "disk" && !seen[$2]++ {print $2}')"
  # Resolve to stable by-id paths for GRUB
  realBootDevicesById=()
  for realBootDevice in $realBootDevices; do
    realBootDevicesById+=($(find -L /dev/disk/by-id/ -type b -samefile "$realBootDevice" | sort -us | head -n1))
  done
  # Pre-seed debconf so grub-pc installs non-interactively
  echo "grub-pc grub-pc/install_devices multiselect $(sed 's/ /, /g' <<<"${realBootDevicesById[@]}")" | debconf-set-selections
  apt-get -y install --no-install-recommends grub-pc
  apt-get -y purge grub-efi-amd64-bin 2>/dev/null || true
fi

# Clean up unused packages from boot mode purge
apt-get -y autoremove
apt-get -y clean

# Generate unique machine ID (cloud-init cleared it during cleanup)
systemd-machine-id-setup

# Rebuild initramfs with mdadm + LUKS modules
update-initramfs -u

# Remove OVH deployment artifacts
rm -rf /root/.ovh/
