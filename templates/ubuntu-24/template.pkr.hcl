locals {
  cd_content = {
    "meta-data" = yamlencode({
      instance-id = "iid-local01"
    })

  }
}

variable cpus {
  type    = number
  default = 4
}

variable memory {
  type    = number
  default = 4096
}

# At least same as original Ubuntu image
variable disk_size {
  type    = string
  default = "3.5G"
}

variable img_format {
  type    = string
  default = "qcow2"
}

variable output_directory {
  type    = string
  default = "./output"
}

source "qemu" "ubuntu-24-zfs" {
  iso_url                   = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
  iso_checksum              = "file:https://cloud-images.ubuntu.com/releases/24.04/release/SHA256SUMS"
  accelerator               = "kvm"
  cpus                      = var.cpus
  memory                    = var.memory
  disk_image                = true
  disk_size                 = "4G"
  boot_wait                 = "3s"
  # Main disk for ZFS root partition
  disk_additional_size      = [var.disk_size]
  disk_cache                = "unsafe"
  disk_discard              = "unmap"
  disk_detect_zeroes        = "unmap"
  format                    = var.img_format
  net_device                = "virtio-net"
  headless                  = true
  qemu_binary               = "qemu-system-x86_64"
  ssh_timeout               = "30s"
  cd_files                  = ["./cloud-init/*"]
  cd_label                  = "cidata"
  ssh_password              = "ubuntu"
  ssh_username              = "ubuntu"
  qemuargs                  = [["-serial", "stdio"]]
  output_directory          = var.output_directory
  vm_name                   = "${source.name}.${var.img_format}"
}

build {
  sources = ["source.qemu.ubuntu-24-zfs"]

	provisioner "file" {
		source = "files/zfs-growpart-root.cfg"
		destination = "/tmp/zfs-growpart-root.cfg"
	}

	provisioner "file" {
		source = "scripts/chroot-bootstrap.sh"
		destination = "/tmp/chroot-bootstrap.sh"
	}

  provisioner "shell" {
    scripts = [
      "scripts/prepare-zfs-root.sh",
    ]
  }
}
