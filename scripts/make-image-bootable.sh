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

# Append serial console parameters from the OVH rescue environment
console_parameters="$(grep -Po '\bconsole=\S+' /proc/cmdline | paste -s -d' ')" || true
if [ -n "$console_parameters" ]; then
  echo "GRUB_CMDLINE_LINUX=\"\$GRUB_CMDLINE_LINUX $console_parameters\"" \
    > /etc/default/grub.d/99-serial-console.cfg
fi

# Install GRUB for the server's boot mode
if [ -d /sys/firmware/efi ]; then
  echo "INFO: Installing GRUB for UEFI boot"
  apt-get -y install --no-install-recommends grub-efi-amd64
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --no-nvram
  apt-get -y purge grub-pc-bin 2>/dev/null || true
else
  echo "INFO: Installing GRUB for legacy boot"
  read -r bootDevice _ < <(findmnt -A -c -e -l -n -T /boot/ -o SOURCE,FSTYPE)
  realBootDevices="$(lsblk -n -p -b -l -o TYPE,NAME "$bootDevice" -s | awk '$1 == "disk" && !seen[$2]++ {print $2}')"
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
