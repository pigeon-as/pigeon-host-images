#!/bin/bash
set -ex
# Build-time: seal /usr as immutable squashfs + dm-verity, build versioned UKI.
# IMAGE_VERSION: image version for A/B updates (default: 0.0.0).
# PCR_SIGNING_KEY: path to RSA-2048 private key for PCR 11 signing (CI secret).

IMAGE_VERSION="${IMAGE_VERSION:-0.0.0}"
KVER=$(ls /lib/modules/ | sort -V | tail -1)
VMLINUZ="/boot/vmlinuz-${KVER}"
PCR_PUBKEY="/etc/pigeon/pcr-signing-pubkey.pem"

# crypttab — dracut bakes this into the initrd for systemd-cryptsetup
cat > /etc/crypttab <<'EOF'
root /dev/md1 - tpm2-device=auto
EOF

# Embed IMAGE_VERSION in os-release (baked into immutable /usr)
echo "IMAGE_VERSION=${IMAGE_VERSION}" >> /usr/lib/os-release

# Squashfs — versioned filename for A/B updates
mksquashfs /usr /usr_${IMAGE_VERSION}.img -comp zstd -no-exports -noappend -quiet
SQUASH_SIZE=$(stat -c%s /usr_${IMAGE_VERSION}.img)
HASH_OFFSET=$(( (SQUASH_SIZE + 4095) / 4096 * 4096 ))
truncate -s "${HASH_OFFSET}" /usr_${IMAGE_VERSION}.img

# dm-verity hash tree appended at HASH_OFFSET (ChromeOS single-file pattern)
VERITY_OUT=$(veritysetup format /usr_${IMAGE_VERSION}.img /usr_${IMAGE_VERSION}.img --hash-offset="${HASH_OFFSET}" 2>&1)
ROOT_HASH=$(echo "$VERITY_OUT" | grep "Root hash:" | awk '{print $NF}')

# dracut initrd with systemd generators
dracut --force --kver "${KVER}" /tmp/initrd.img \
  --add "dm rootfs-block mdraid systemd-cryptsetup systemd-veritysetup systemd-pcrphase" \
  --force-drivers "loop dm-verity dm-crypt raid1 squashfs btrfs"

# UKI cmdline = base (CIS hardening) + LUKS root + verity params
CMDLINE="$(cat /etc/kernel/cmdline) root=/dev/mapper/root ro"
CMDLINE="${CMDLINE} usrhash=${ROOT_HASH}"
CMDLINE="${CMDLINE} systemd.verity_usr_data=/usr_${IMAGE_VERSION}.img systemd.verity_usr_hash=/usr_${IMAGE_VERSION}.img"
CMDLINE="${CMDLINE} systemd.verity_usr_options=hash-offset=${HASH_OFFSET}"
printf '%s' "${CMDLINE}" > /tmp/cmdline.txt

# Build UKI — sign for PCR 11 at enter-initrd phase only (LUKS unseals in initrd)
UKIFY_ARGS=(build --linux="${VMLINUZ}" --initrd=/tmp/initrd.img --cmdline=@/tmp/cmdline.txt --output=/boot/pigeon_${IMAGE_VERSION}.efi)
if [ -n "${PCR_SIGNING_KEY}" ] && [ -f "${PCR_SIGNING_KEY}" ]; then
  UKIFY_ARGS+=(--pcr-private-key="${PCR_SIGNING_KEY}" --pcr-public-key="${PCR_PUBKEY}" --phases='enter-initrd' --pcr-banks=sha256 --pcrpkey="${PCR_PUBKEY}")
fi
ukify "${UKIFY_ARGS[@]}"

rm -f /tmp/initrd.img /tmp/cmdline.txt
