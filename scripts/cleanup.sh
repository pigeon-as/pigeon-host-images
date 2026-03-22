#!/bin/bash -ex

export DEBIAN_FRONTEND=noninteractive

systemctl daemon-reload
cloud-init clean --logs
rm -f /etc/ssh/ssh_host_*
rm -rf /root/.ssh /root/.cache
passwd -l root
rm -f /root/.bash_history /root/.nano_history
history -c 2>/dev/null || true
rm -f /etc/netplan/50-cloud-init.yaml
apt-get autoremove --purge -yq
apt-get clean -yq
rm -rf /var/tmp/* /tmp/*
find /var/log -type f -exec truncate -s 0 {} \;
rm -f /etc/machine-id
