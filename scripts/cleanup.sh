#!/bin/bash -ex
# Final image cleanup.

export DEBIAN_FRONTEND=noninteractive

systemctl daemon-reload

# Reset cloud-init for first boot.
cloud-init clean --logs

# Remove SSH host keys (regenerated on first boot).
rm -f /etc/ssh/ssh_host_*

# Remove root SSH artifacts from packer build.
rm -rf /root/.ssh /root/.cache

# Lock root password set during build.
passwd -l root

# Remove shell history from build.
rm -f /root/.bash_history /root/.nano_history
history -c 2>/dev/null || true

# Remove cloud-init netplan from build environment.
rm -f /etc/netplan/50-cloud-init.yaml

# Clean packages.
apt-get autoremove --purge -yq
apt-get clean -yq

# Clean temp and log artifacts from build.
rm -rf /var/tmp/* /tmp/*
find /var/log -type f -exec truncate -s 0 {} \;

# Remove machine-id (regenerated at deploy time).
rm -f /etc/machine-id
