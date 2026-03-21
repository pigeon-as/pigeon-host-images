#!/bin/bash -ex
set -o pipefail
# Swap cloud kernel for generic bare metal kernel.

export DEBIAN_FRONTEND=noninteractive

# Remove cloud kernel and cloud-specific GRUB config.
rm -f /etc/default/grub.d/50-cloudimg-settings.cfg
apt-get update
apt-get purge -y linux-virtual 'linux-image-*' 'linux-headers-*'

# Install generic kernel, microcode, bare metal essentials.
apt-get install -y linux-image-generic linux-headers-generic
apt-get install -y mdadm lvm2 amd64-microcode intel-microcode curl jq

# Pre-download GRUB for both UEFI and legacy boot.
# make-image-bootable.sh installs the correct one at deploy time.
apt-get install -y --download-only grub-efi-amd64 || true
apt-get install -y --download-only grub-pc || true
echo "grub-efi-amd64 grub2/update_nvram boolean false" | debconf-set-selections

# GRUB: bare metal settings.
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="nomodeset iommu=pt nosmt=force init_on_alloc=1 slab_nomerge vsyscall=none lockdown=integrity"/' /etc/default/grub
grep -q '^GRUB_GFXPAYLOAD_LINUX=' /etc/default/grub || \
  echo 'GRUB_GFXPAYLOAD_LINUX="text"' >> /etc/default/grub

update-grub

# GRUB password: prevent boot parameter editing at physical console.
# Generate a random password and hash it — cleartext is discarded.
# Management is via SSH, not console — nobody needs this password.
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
# Allow normal boot without password (--unrestricted on menu entries).
sed -i 's/--class os/--class os --unrestricted/' /etc/grub.d/10_linux
update-grub

# Disable cloud-init modules that interfere with bare metal partitioning.
sed -Ei '/^ - (grub-dpkg|growpart|resizefs)/d' /etc/cloud/cloud.cfg

apt-get -y dist-upgrade
