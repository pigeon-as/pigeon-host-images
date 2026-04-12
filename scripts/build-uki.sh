#!/bin/bash
set -euo pipefail
# Build-time: seal /usr as immutable squashfs + dm-verity, build versioned UKI.
#
# Required:
#   IMAGE_VERSION        — image version for A/B updates (default: 0.0.0)
#
# Signing (base64-encoded PEM, standard CI secret pattern):
#   PCR_SIGNING_KEY      — RSA-2048 private key for PCR 11 PolicyAuthorize.
#                          Required for production. Set SKIP_SIGNING=true for dev builds.

IMAGE_VERSION="${IMAGE_VERSION:-0.0.0}"
KVER=$(ls /lib/modules/ | sort -V | tail -1)
VMLINUZ="/boot/vmlinuz-${KVER}"
SIGNING_DIR=$(mktemp -d)
trap 'rm -rf "${SIGNING_DIR}"' EXIT

# Decode base64 signing keys to temp files (CI secrets → file)
decode_key() {
  local var_name="$1" out_path="$2"
  local val="${!var_name}"
  if [ -n "${val}" ]; then
    echo "${val}" | base64 -d > "${out_path}"
    echo "  ${var_name}: decoded"
    return 0
  fi
  return 1
}

# PCR signing key — required unless explicitly skipped
PCR_KEY="${SIGNING_DIR}/pcr-key.pem"
PCR_PUBKEY="/etc/pigeon/pcr-signing-pubkey.pem"
if decode_key PCR_SIGNING_KEY "${PCR_KEY}"; then
  # Derive public key and persist in image (needed by systemd-cryptenroll PolicyAuthorize)
  openssl rsa -in "${PCR_KEY}" -pubout -out "${PCR_PUBKEY}" 2>/dev/null
elif [ "${SKIP_SIGNING}" = "true" ]; then
  echo "WARNING: PCR signing disabled — evil maid protection inactive. Dev builds only."
  PCR_KEY=""
else
  echo "ERROR: PCR_SIGNING_KEY required. Set SKIP_SIGNING=true for dev builds."
  exit 1
fi

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
veritysetup format /usr_${IMAGE_VERSION}.img /usr_${IMAGE_VERSION}.img \
  --hash-offset="${HASH_OFFSET}" --root-hash-file=/tmp/root-hash
ROOT_HASH=$(< /tmp/root-hash)

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
if [ -n "${PCR_KEY}" ]; then
  UKIFY_ARGS+=(--pcr-private-key="${PCR_KEY}" --pcr-public-key="${PCR_PUBKEY}" --phases='enter-initrd' --pcr-banks=sha256 --pcrpkey="${PCR_PUBKEY}")
fi
ukify "${UKIFY_ARGS[@]}"

rm -f /tmp/initrd.img /tmp/cmdline.txt
