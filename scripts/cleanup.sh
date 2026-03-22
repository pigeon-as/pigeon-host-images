#!/bin/bash
set -ex
export DEBIAN_FRONTEND=noninteractive

systemctl daemon-reload
# Reset cloud-init for first-boot
cloud-init clean --logs
# Remove build-time SSH host keys
rm -f /etc/ssh/ssh_host_*
# Build-time SSH keys + cache
rm -rf /root/.ssh /root/.cache
# Lock root password
passwd -l root
rm -f /root/.bash_history /root/.nano_history
history -c 2>/dev/null || true
# Cloud netplan (OVH uses its own)
rm -f /etc/netplan/50-cloud-init.yaml
apt-get autoremove --purge -yq
apt-get clean -yq
rm -rf /var/tmp/* /tmp/*
find /var/log -type f -exec truncate -s 0 {} \;
# Unique ID generated on first boot
rm -f /etc/machine-id
