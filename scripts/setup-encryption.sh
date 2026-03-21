#!/bin/bash -ex
# Install LUKS encryption packages for /encrypted partition.
#
# cryptsetup: LUKS2 disk encryption
# tpm2-tools: TPM2 interaction for systemd-cryptenroll
#
# The actual partition setup (luksFormat, systemd-cryptenroll, mount)
# happens at first boot via the provisioning step, not at image build time.

apt-get -y install cryptsetup tpm2-tools
