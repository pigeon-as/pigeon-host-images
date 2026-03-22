#!/bin/bash
set -exo pipefail
# Adapted from https://github.com/ovh/bringyourownlinux/blob/master/make_image_bootable.sh

export DEBIAN_FRONTEND=noninteractive

if [ -f /usr/share/mdadm/mkconf ]; then
  rm -f /etc/mdadm/mdadm.conf /etc/mdadm.conf
  /usr/share/mdadm/mkconf force-generate
fi

console_parameters="$(grep -Po '\bconsole=\S+' /proc/cmdline | paste -s -d' ')" || true
if [ -n "$console_parameters" ] && [ -f /etc/default/grub ]; then
  if ! grep '^GRUB_CMDLINE_LINUX="' /etc/default/grub | grep -qF "$console_parameters"; then
    sed -Ei "s/(^GRUB_CMDLINE_LINUX=.*)\"\$/\1 $console_parameters\"/" /etc/default/grub
  fi
fi

if lsblk -lno FSTYPE 2>/dev/null | grep -qxiF zfs_member; then
  apt-get -y install linux-headers-generic zfs-dkms zfs-initramfs zfs-zed
  systemctl enable zfs-import-scan.service
fi

if [ -d /sys/firmware/efi ]; then
  echo "INFO: Installing GRUB for UEFI boot"
  apt-get -y install --no-install-recommends grub-efi-amd64
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --no-nvram
  apt-get -y purge grub-pc-bin 2>/dev/null || true
else
  echo "INFO: Installing GRUB for legacy boot"
  read -r bootDevice bootDeviceType < <(findmnt -A -c -e -l -n -T /boot/ -o SOURCE,FSTYPE)
  if [[ "$bootDeviceType" == "zfs" ]]; then
    bootDevices="$(zpool status -LP "${bootDevice%/*}" | grep -Po '/dev/\S+')"
  else
    bootDevices="$bootDevice"
  fi
  realBootDevices="$(lsblk -n -p -b -l -o TYPE,NAME "$bootDevices" -s | awk '$1 == "disk" && !seen[$2]++ {print $2}')"
  realBootDevicesById=()
  for realBootDevice in $realBootDevices; do
    # shellcheck disable=SC2207
    realBootDevicesById+=($(find -L /dev/disk/by-id/ -type b -samefile "$realBootDevice" | sort -us | head -n1))
  done
  # shellcheck disable=SC2001
  echo "grub-pc grub-pc/install_devices multiselect $(sed 's/ /, /g' <<<"${realBootDevicesById[@]}")" | debconf-set-selections
  apt-get -y install --no-install-recommends grub-pc
  apt-get -y purge grub-efi-amd64-bin 2>/dev/null || true
fi

apt-get -y autoremove
apt-get -y clean

systemd-machine-id-setup
update-initramfs -u
rm -rf /root/.ovh/
