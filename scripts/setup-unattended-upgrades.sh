#!/bin/bash
set -ex
export DEBIAN_FRONTEND=noninteractive

apt-get install -y unattended-upgrades

# Enable unattended-upgrades with security-only updates.
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
// Kernel updates require image rebuild (UKI + TPM PCR 11 re-seal).
// Auto-upgrading the kernel would produce wrong PCR 11 → LUKS locked → bricked server.
Unattended-Upgrade::Package-Blacklist {
    "linux-image-";
    "linux-headers-";
    "linux-modules-";
};
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
