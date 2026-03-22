#!/bin/bash
set -eo pipefail

export DEBIAN_FRONTEND=noninteractive

# Remove cloud GRUB settings
rm -f /etc/default/grub.d/50-cloudimg-settings.cfg
apt-get update
# Replace cloud kernel with generic
apt-get purge -y linux-virtual 'linux-image-*' 'linux-headers-*'

apt-get install -y linux-image-generic linux-headers-generic
# Bare metal packages
apt-get install -y mdadm lvm2 amd64-microcode intel-microcode curl jq

# Pre-download GRUB for both boot modes — make-image-bootable.sh
# runs chrooted without network and picks the right one.
apt-get install -y --download-only grub-efi-amd64 || true
apt-get install -y --download-only grub-pc || true
# Prevent GRUB EFI from writing NVRAM during image build
echo "grub-efi-amd64 grub2/update_nvram boolean false" | debconf-set-selections

# Hardened boot parameters
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="nomodeset iommu=pt nosmt=force init_on_alloc=1 slab_nomerge vsyscall=none lockdown=integrity"/' /etc/default/grub
# Text-only console
grep -q '^GRUB_GFXPAYLOAD_LINUX=' /etc/default/grub || \
  echo 'GRUB_GFXPAYLOAD_LINUX="text"' >> /etc/default/grub

update-grub

# GRUB password — prevent boot parameter editing at physical console
grub_pw=$(head -c 32 /dev/urandom | base64)
grub_hash=$(echo -e "${grub_pw}\n${grub_pw}" | grub-mkpasswd-pbkdf2 2>/dev/null | awk '/grub.pbkdf2/ {print $NF}')
unset grub_pw
cat > /etc/grub.d/42_password << EOF
#!/bin/sh
cat << 'GRUBCFG'
set superusers="pigeon"
password_pbkdf2 pigeon ${grub_hash}
GRUBCFG
EOF
chmod +x /etc/grub.d/42_password
# Allow normal boot without password (only editing needs it)
sed -i 's/--class os/--class os --unrestricted/' /etc/grub.d/10_linux
update-grub

# Prevent cloud-init from reinstalling cloud GRUB or resizing partitions
sed -Ei '/^\s*-\s*(grub-dpkg|growpart|resizefs)/d' /etc/cloud/cloud.cfg

apt-get -y dist-upgrade
