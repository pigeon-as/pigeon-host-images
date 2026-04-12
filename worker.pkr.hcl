packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "ubuntu_version" {
  type    = string
  default = "24.04"
}

variable "image_version" {
  type    = string
  default = "0.0.0"
}

source "qemu" "worker" {
  iso_url      = "https://cloud-images.ubuntu.com/releases/${var.ubuntu_version}/release/ubuntu-${var.ubuntu_version}-server-cloudimg-amd64.img"
  iso_checksum = "file:https://cloud-images.ubuntu.com/releases/${var.ubuntu_version}/release/SHA256SUMS"

  disk_image       = true
  disk_size        = "5G"
  disk_compression = true
  format           = "qcow2"
  headless         = true

  accelerator = "kvm"
  cpus        = 2
  memory      = 2048
  boot_wait   = "10s"

  ssh_username           = "root"
  ssh_password           = "packer"
  ssh_timeout            = "10m"
  ssh_wait_timeout       = "1h"
  ssh_handshake_attempts = 500

  shutdown_command = "sudo -S shutdown -P now"
  output_directory = "build/worker"
  vm_name          = "worker.qcow2"

  cd_files = ["cloud-init/user-data", "cloud-init/meta-data"]
  cd_label = "cidata"

  qemuargs = [
    ["-serial", "file:build/serial-worker.log"],
  ]
}

build {
  sources = ["source.qemu.worker"]

  provisioner "file" {
    source      = "templates/cmdline"
    destination = "/etc/kernel/cmdline"
  }

  provisioner "shell" {
    script = "scripts/setup-kernel.sh"
  }

  provisioner "shell" {
    scripts = [
      "scripts/setup-apt-sources.sh",
      "scripts/setup-encryption.sh",
      "scripts/setup-nftables.sh",
      "scripts/setup-pigeon.sh",
      "scripts/setup-pigeon-mesh.sh",
      "scripts/setup-pigeon-enroll.sh",
      "scripts/setup-pigeon-template.sh",
      "scripts/setup-pigeon-fence.sh",
      "scripts/setup-pigeon-petname.sh",
      "scripts/setup-unbound.sh",
      "scripts/setup-vault.sh",
      "scripts/setup-consul.sh",
      "scripts/setup-nomad.sh",
      "scripts/setup-firecracker.sh",
      "scripts/setup-cni.sh",
      "scripts/setup-driver.sh",
      "scripts/setup-lvm-plugin.sh",
      "scripts/setup-bird.sh",
      "scripts/setup-haproxy.sh",
    ]
    environment_vars = [
      "PIGEON_MESH_VERSION=0.0.1-beta.1",
      "PIGEON_ENROLL_VERSION=0.0.1-beta.1",
      "PIGEON_TEMPLATE_VERSION=0.0.1-beta.1",
      "PIGEON_FENCE_VERSION=0.0.1-beta.1",
      "PIGEON_PETNAME_VERSION=0.0.1-beta.1",
      "VAULT_VERSION=1.19.0-1",
      "CONSUL_VERSION=1.20.6-1",
      "NOMAD_VERSION=1.11.2-1",
      "FIRECRACKER_VERSION=1.14.2",
      "CNI_VERSION=1.6.2",
      "DRIVER_VERSION=0.0.1-beta.1",
      "LVM_PLUGIN_VERSION=0.0.1-beta.1",
    ]
  }

  provisioner "file" {
    source      = "templates/pigeon-mesh.service"
    destination = "/etc/systemd/system/pigeon-mesh.service"
  }

  provisioner "file" {
    source      = "templates/pigeon-fence.service"
    destination = "/etc/systemd/system/pigeon-fence.service"
  }

  provisioner "file" {
    source      = "templates/mesh.json.tpl"
    destination = "/etc/pigeon/mesh.json.tpl"
  }

  provisioner "file" {
    source      = "templates/consul.hcl.tpl"
    destination = "/etc/pigeon/consul.hcl.tpl"
  }

  provisioner "file" {
    source      = "templates/nomad.hcl.tpl"
    destination = "/etc/pigeon/nomad.hcl.tpl"
  }

  provisioner "file" {
    source      = "templates/bootstrap-worker.tmpl.hcl"
    destination = "/etc/pigeon/bootstrap.tmpl.hcl"
  }

  provisioner "file" {
    source      = "templates/reconcile-worker.tmpl.hcl"
    destination = "/etc/pigeon/reconcile.tmpl.hcl"
  }

  provisioner "file" {
    source      = "templates/pigeon-template-reconcile.service"
    destination = "/etc/systemd/system/pigeon-template-reconcile.service"
  }

  provisioner "file" {
    source      = "templates/vault-agent.hcl"
    destination = "/etc/pigeon/vault-agent.hcl"
  }

  provisioner "file" {
    source      = "templates/nomad-cert.ctmpl"
    destination = "/etc/pigeon/nomad-cert.ctmpl"
  }

  provisioner "file" {
    source      = "templates/nomad-key.ctmpl"
    destination = "/etc/pigeon/nomad-key.ctmpl"
  }

  provisioner "file" {
    source      = "templates/vault-agent.service"
    destination = "/etc/systemd/system/vault-agent.service"
  }

  provisioner "file" {
    source      = "templates/fence-worker.hcl"
    destination = "/etc/pigeon/fence.hcl"
  }

  provisioner "file" {
    source      = "templates/unbound.conf.tpl"
    destination = "/etc/pigeon/unbound.conf.tpl"
  }

  provisioner "file" {
    source      = "templates/infra.zone.tpl"
    destination = "/etc/pigeon/infra.zone.tpl"
  }

  provisioner "file" {
    source      = "templates/resolv.conf.tpl"
    destination = "/etc/pigeon/resolv.conf.tpl"
  }

  provisioner "file" {
    source      = "templates/consul.service"
    destination = "/etc/systemd/system/consul.service"
  }

  provisioner "file" {
    source      = "templates/nomad.service"
    destination = "/etc/systemd/system/nomad.service"
  }

  provisioner "file" {
    source      = "templates/nomad-cert.path"
    destination = "/etc/systemd/system/nomad-cert.path"
  }

  provisioner "file" {
    source      = "templates/nftables.conf"
    destination = "/etc/nftables.conf"
  }

  provisioner "file" {
    source      = "templates/sysctl.conf"
    destination = "/etc/sysctl.d/99-pigeon.conf"
  }

  provisioner "file" {
    source      = "templates/limits.conf"
    destination = "/etc/security/limits.d/99-pigeon.conf"
  }

  provisioner "file" {
    source      = "templates/sshd.conf"
    destination = "/etc/ssh/sshd_config.d/99-pigeon.conf"
  }

  provisioner "file" {
    source      = "templates/blacklist.conf"
    destination = "/etc/modprobe.d/99-pigeon-blacklist.conf"
  }

  provisioner "file" {
    source      = "templates/kvm.conf"
    destination = "/etc/modprobe.d/99-pigeon-kvm.conf"
  }

  # sysupdate.d configs go into /usr (sealed into immutable squashfs by seal-rootfs.sh)
  provisioner "shell" {
    inline = ["mkdir -p /usr/lib/sysupdate.d"]
  }

  provisioner "file" {
    source      = "templates/sysupdate-50-usr.transfer"
    destination = "/usr/lib/sysupdate.d/50-usr.transfer"
  }

  provisioner "file" {
    source      = "templates/sysupdate-70-uki.transfer"
    destination = "/usr/lib/sysupdate.d/70-uki.transfer"
  }

  # Service state management — single source of truth.
  # apt packages auto-enable during install; disable what we don't want,
  # then enable exactly what this image needs.
  provisioner "shell" {
    inline = [
      # Disable apt-installed defaults not needed on workers
      "systemctl disable vault",

      # Enable services for this image
      "systemctl enable nftables",
      "systemctl enable pigeon-mesh",
      "systemctl enable pigeon-fence",
      "systemctl enable pigeon-template-reconcile",
      "systemctl enable unbound",
      "systemctl enable systemd-bless-boot",
      "systemctl disable systemd-resolved",
      "systemctl enable consul",
      "systemctl enable vault-agent",
      "systemctl enable nomad-cert.path",
      "systemctl enable bird",
      "systemctl enable haproxy",
    ]
  }

  provisioner "shell" {
    script = "scripts/setup-hugepages.sh"
  }

  # seal-rootfs.sh creates the immutable /usr squashfs + dm-verity image
  # and builds the UKI (kernel + dracut initrd + cmdline with verity root hash).
  # Must run after all packages/binaries are installed (everything in /usr is sealed).
  # PCR_SIGNING_KEY: set by CI to sign UKI for TPM2 PolicyAuthorize.
  provisioner "shell" {
    script = "scripts/seal-rootfs.sh"
    environment_vars = [
      "IMAGE_VERSION=${var.image_version}",
    ]
  }

  # Download sysupdate artifacts for CI publishing to updates.pigeon.as
  provisioner "file" {
    source      = "/usr_${var.image_version}.img"
    destination = "build/worker/pigeon_${var.image_version}.usr.img"
    direction   = "download"
  }

  provisioner "file" {
    source      = "/boot/pigeon_${var.image_version}.efi"
    destination = "build/worker/pigeon_${var.image_version}.efi"
    direction   = "download"
  }

  provisioner "shell" {
    script = "scripts/setup-ovh.sh"
  }

  provisioner "file" {
    source      = "scripts/make-image-bootable.sh"
    destination = "/root/.ovh/make_image_bootable.sh"
  }

  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }
}
