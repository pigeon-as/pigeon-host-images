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

variable "skip_signing" {
  type    = string
  default = "true"
}

variable "pcr_signing_key" {
  type      = string
  default   = ""
  sensitive = true
}

source "qemu" "control-plane" {
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

  shutdown_command = "shutdown -P now"
  output_directory = "build/control-plane"
  vm_name          = "control-plane.qcow2"

  cd_files = ["cloud-init/user-data", "cloud-init/meta-data"]
  cd_label = "cidata"

  qemuargs = [
    ["-serial", "file:build/serial-control-plane.log"],
  ]
}

build {
  sources = ["source.qemu.control-plane"]

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
      "scripts/setup-ek-ca.sh",
      "scripts/setup-pigeon-template.sh",
      "scripts/setup-pigeon-fence.sh",
      "scripts/setup-vault.sh",
      "scripts/setup-vault-storage.sh",
      "scripts/setup-consul.sh",
      "scripts/setup-nomad.sh",
      "scripts/setup-unbound.sh",
    ]
    environment_vars = [
      "PIGEON_MESH_VERSION=0.0.1-beta.1",
      "PIGEON_ENROLL_VERSION=0.0.1-beta.1",
      "PIGEON_TEMPLATE_VERSION=0.0.1-beta.1",
      "PIGEON_FENCE_VERSION=0.0.1-beta.1",
      "VAULT_VERSION=1.19.0-1",
      "CONSUL_VERSION=1.20.6-1",
      "NOMAD_VERSION=1.11.2-1",
    ]
  }

  provisioner "file" {
    source      = "templates/pigeon-mesh.service"
    destination = "/etc/systemd/system/pigeon-mesh.service"
  }

  provisioner "file" {
    source      = "templates/pigeon-enroll.service"
    destination = "/etc/systemd/system/pigeon-enroll.service"
  }

  provisioner "file" {
    source      = "templates/pigeon-template-reconcile-server.service"
    destination = "/etc/systemd/system/pigeon-template-reconcile.service"
  }

  provisioner "file" {
    source      = "templates/pigeon-fence.service"
    destination = "/etc/systemd/system/pigeon-fence.service"
  }

  provisioner "file" {
    source      = "templates/pigeon-fence.path"
    destination = "/etc/systemd/system/pigeon-fence.path"
  }

  provisioner "file" {
    source      = "templates/vault-agent.path"
    destination = "/etc/systemd/system/vault-agent.path"
  }

  provisioner "file" {
    source      = "templates/reconcile-server.hcl"
    destination = "/etc/pigeon/reconcile.hcl"
  }

  provisioner "file" {
    source      = "templates/fence-server.hcl"
    destination = "/etc/pigeon/fence.hcl"
  }

  provisioner "file" {
    source      = "templates/mesh.json.tpl"
    destination = "/etc/pigeon/mesh.json.tpl"
  }

  provisioner "file" {
    source      = "templates/consul-server.hcl.tpl"
    destination = "/etc/pigeon/consul-server.hcl.tpl"
  }

  provisioner "file" {
    source      = "templates/nomad-server.hcl.tpl"
    destination = "/etc/pigeon/nomad-server.hcl.tpl"
  }

  provisioner "file" {
    source      = "templates/vault.hcl.tpl"
    destination = "/etc/pigeon/vault.hcl.tpl"
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
    source      = "templates/setup-worker.sh.tpl"
    destination = "/etc/pigeon/setup-worker.sh.tpl"
  }

  # JSON bundles served by pigeon-enroll via `read template/enroll-*`.
  provisioner "file" {
    source      = "templates/enroll-server.json.tpl"
    destination = "/etc/pigeon/templates/enroll-server.json.tpl"
  }

  provisioner "file" {
    source      = "templates/enroll-worker.json.tpl"
    destination = "/etc/pigeon/templates/enroll-worker.json.tpl"
  }

  provisioner "file" {
    source      = "templates/pigeon-template.path"
    destination = "/etc/systemd/system/pigeon-template.path"
  }

  provisioner "file" {
    source      = "templates/pigeon-identity-ensure-server.service"
    destination = "/etc/systemd/system/pigeon-identity-ensure.service"
  }

  provisioner "file" {
    source      = "templates/vault.service"
    destination = "/etc/systemd/system/vault.service"
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
    source      = "scripts/consul-acl-bootstrap"
    destination = "/usr/local/bin/consul-acl-bootstrap"
  }

  provisioner "file" {
    source      = "templates/consul-acl-bootstrap.service"
    destination = "/etc/systemd/system/consul-acl-bootstrap.service"
  }

  provisioner "file" {
    source      = "scripts/vault-init"
    destination = "/usr/local/bin/vault-init"
  }

  provisioner "file" {
    source      = "templates/vault-init.service"
    destination = "/etc/systemd/system/vault-init.service"
  }

  provisioner "file" {
    source      = "scripts/luks-recovery"
    destination = "/usr/local/bin/luks-recovery"
  }

  provisioner "file" {
    source      = "templates/luks-recovery-server.service"
    destination = "/etc/systemd/system/luks-recovery.service"
  }

  provisioner "file" {
    source      = "templates/vault-agent-server.hcl"
    destination = "/etc/pigeon/vault-agent.hcl"
  }

  provisioner "file" {
    source      = "templates/vault-agent-server.service"
    destination = "/etc/systemd/system/vault-agent.service"
  }

  provisioner "file" {
    source      = "templates/consul-server-cert.ctmpl"
    destination = "/etc/pigeon/consul-server-cert.ctmpl"
  }

  provisioner "file" {
    source      = "templates/consul-server-key.ctmpl"
    destination = "/etc/pigeon/consul-server-key.ctmpl"
  }

  provisioner "file" {
    source      = "templates/nomad-server-cert.ctmpl"
    destination = "/etc/pigeon/nomad-server-cert.ctmpl"
  }

  provisioner "file" {
    source      = "templates/nomad-server-key.ctmpl"
    destination = "/etc/pigeon/nomad-server-key.ctmpl"
  }

  provisioner "file" {
    source      = "templates/consul-ca.ctmpl"
    destination = "/etc/pigeon/consul-ca.ctmpl"
  }

  provisioner "file" {
    source      = "templates/nomad-ca.ctmpl"
    destination = "/etc/pigeon/nomad-ca.ctmpl"
  }

  provisioner "file" {
    source      = "templates/mesh-server-cert.ctmpl"
    destination = "/etc/pigeon/mesh-server-cert.ctmpl"
  }

  provisioner "file" {
    source      = "templates/mesh-server-key.ctmpl"
    destination = "/etc/pigeon/mesh-server-key.ctmpl"
  }

  provisioner "file" {
    source      = "templates/mesh-ca.ctmpl"
    destination = "/etc/pigeon/mesh-ca.ctmpl"
  }

  provisioner "file" {
    source      = "templates/auth-server-cert.ctmpl"
    destination = "/etc/pigeon/auth-server-cert.ctmpl"
  }

  provisioner "file" {
    source      = "templates/auth-server-key.ctmpl"
    destination = "/etc/pigeon/auth-server-key.ctmpl"
  }

  provisioner "file" {
    source      = "templates/nftables-server.conf"
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
    source      = "scripts/extract-ek-ca.sh"
    destination = "/usr/local/bin/extract-ek-ca.sh"
  }

  provisioner "shell" {
    script = "scripts/setup-sysupdate.sh"
  }

  provisioner "file" {
    source      = "templates/sysupdate-50-usr.transfer"
    destination = "/usr/lib/sysupdate.d/50-usr.transfer"
  }

  provisioner "file" {
    source      = "templates/sysupdate-70-uki.transfer"
    destination = "/usr/lib/sysupdate.d/70-uki.transfer"
  }

  provisioner "shell" {
    inline = [
      "systemctl disable systemd-resolved",

      "chmod 0755 /usr/local/bin/vault-init /usr/local/bin/luks-recovery /usr/local/bin/consul-acl-bootstrap",

      "systemctl enable nftables",
      "systemctl enable pigeon-mesh",
      "systemctl enable pigeon-fence",
      "systemctl enable pigeon-enroll",
      "systemctl enable pigeon-template.path",
      "systemctl enable pigeon-template-reconcile",
      "systemctl enable pigeon-identity-ensure",
      "systemctl enable pigeon-fence.path",
      "systemctl enable vault-agent.path",
      "systemctl enable consul-acl-bootstrap",
      "systemctl enable vault-init",
      "systemctl enable luks-recovery",
      "systemctl enable vault-agent",
      "systemctl enable vault",
      "systemctl enable consul",
      "systemctl enable nomad",
      "systemctl enable unbound",
      "systemctl enable systemd-bless-boot",
    ]
  }

  # Must run after all packages/binaries are installed.
  provisioner "shell" {
    script = "scripts/build-uki.sh"
    environment_vars = [
      "IMAGE_VERSION=${var.image_version}",
      "SKIP_SIGNING=${var.skip_signing}",
      "PCR_SIGNING_KEY=${var.pcr_signing_key}",
    ]
  }

  # Download sysupdate artifacts for CI publishing to updates.pigeon.as
  provisioner "file" {
    source      = "/usr_${var.image_version}.img"
    destination = "build/control-plane/pigeon_${var.image_version}.usr.img"
    direction   = "download"
  }

  provisioner "file" {
    source      = "/boot/pigeon_${var.image_version}.efi"
    destination = "build/control-plane/pigeon_${var.image_version}.efi"
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
