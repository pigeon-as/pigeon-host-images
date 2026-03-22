packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "control-plane" {
  iso_url      = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
  iso_checksum = "file:https://cloud-images.ubuntu.com/releases/24.04/release/SHA256SUMS"

  disk_image       = true
  disk_size        = "5G"
  disk_compression = true
  format           = "qcow2"
  headless         = true

  ssh_username = "root"
  ssh_password = "packer"
  ssh_timeout  = "10m"

  shutdown_command = "shutdown -P now"
  output_directory = "output/control-plane"
  vm_name          = "control-plane.qcow2"

  cd_files = ["cloud-init/user-data", "cloud-init/meta-data"]
  cd_label = "cidata"

  qemuargs = [
    ["-serial", "stdio"],
    ["-m", "1024"],
  ]
}

build {
  sources = ["source.qemu.control-plane"]

  # Bare metal kernel + GRUB.
  provisioner "shell" {
    script = "scripts/setup-kernel.sh"
  }

  # Install tools.
  provisioner "shell" {
    scripts = [
      "scripts/setup-apt-sources.sh",
      "scripts/setup-encryption.sh",
      "scripts/setup-nftables.sh",
      "scripts/setup-pigeon-mesh.sh",
      "scripts/setup-pigeon-enroll.sh",
      "scripts/setup-pigeon-template.sh",
      "scripts/setup-vault.sh",
      "scripts/setup-consul.sh",
      "scripts/setup-nomad.sh",
      "scripts/setup-unattended-upgrades.sh",
    ]
    environment_vars = [
      "PIGEON_MESH_VERSION=0.1.0",
      "PIGEON_ENROLL_VERSION=0.1.0",
      "PIGEON_TEMPLATE_VERSION=0.1.0",
      "VAULT_VERSION=1.19.0-1",
      "CONSUL_VERSION=1.20.6-1",
      "NOMAD_VERSION=1.11.2-1",
    ]
  }

  # Configs.
  provisioner "file" {
    source      = "templates/pigeon-mesh.service"
    destination = "/etc/systemd/system/pigeon-mesh.service"
  }

  provisioner "file" {
    source      = "templates/pigeon-enroll.service"
    destination = "/etc/systemd/system/pigeon-enroll.service"
  }

  provisioner "file" {
    source      = "templates/pigeon-template.service"
    destination = "/etc/systemd/system/pigeon-template.service"
  }

  provisioner "file" {
    source      = "templates/template-server.hcl"
    destination = "/etc/pigeon/template.hcl"
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
    source      = "templates/pigeon-enroll-actions.service"
    destination = "/etc/systemd/system/pigeon-enroll-actions.service"
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

  # First-boot LUKS setup script (called by Terraform SSH provisioner).
  provisioner "file" {
    source      = "scripts/configure-luks.sh"
    destination = "/usr/local/bin/configure-luks.sh"
  }

  # Enable pigeon services (after service files are deployed).
  provisioner "shell" {
    inline = [
      "systemctl enable pigeon-mesh",
      "systemctl enable pigeon-enroll",
      "systemctl enable pigeon-template",
      "systemctl enable pigeon-enroll-actions",
    ]
  }

  # OVH boot hook.
  provisioner "shell" {
    script = "scripts/setup-ovh.sh"
  }

  provisioner "file" {
    source      = "scripts/make-image-bootable.sh"
    destination = "/root/.ovh/make_image_bootable.sh"
  }

  # Cleanup.
  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }
}
