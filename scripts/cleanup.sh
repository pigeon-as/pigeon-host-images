#!/bin/bash
set -ex
export DEBIAN_FRONTEND=noninteractive

# Pick up all service file changes from provisioners
systemctl daemon-reload

# Reset cloud-init so it runs again on first boot
cloud-init clean --logs

# Remove build-time SSH host keys (regenerated on first boot)
rm -f /etc/ssh/ssh_host_*
# Remove build-time SSH keys and cache
rm -rf /root/.ssh /root/.cache
# Lock root password (SSH key-only access)
passwd -l root
# Remove shell history
rm -f /root/.bash_history /root/.nano_history
history -c 2>/dev/null || true

# Remove cloud netplan (OVH uses its own)
rm -f /etc/netplan/50-cloud-init.yaml

# Clean apt caches and orphaned packages
apt-get autoremove --purge -yq
apt-get clean -yq

# Wipe temp files and logs
rm -rf /var/tmp/* /tmp/*
find /var/log -type f -exec truncate -s 0 {} \;

# Remove machine-id so systemd regenerates it on first boot
rm -f /etc/machine-id
