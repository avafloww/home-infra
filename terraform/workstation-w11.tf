resource "libvirt_pool" "default" {
  name = "default"
  type = "dir"
  path = "/var/lib/libvirt/images"
}

resource "libvirt_volume" "workstation-w11" {
  name = "workstation-w11.qcow2"
  pool = libvirt_pool.default.name
  size = 536870912000 # 500GB
  format = "qcow2"
}

resource "libvirt_domain" "workstation-w11" {
  name = "workstation-w11"
  memory = 32768

  vcpu = 16
  cpu {
    mode = "host-passthrough"
  }

  machine = "q35"
  autostart = false

  boot_device {
    dev = ["cdrom", "hd"]
  }

  firmware = "/usr/share/OVMF/OVMF_CODE_4M.ms.fd"
  nvram {
    file = "/var/lib/libvirt/qemu/nvram/workstation-w11_VARS.fd"
    template = "/usr/share/OVMF/OVMF_VARS_4M.ms.fd"
  }

  disk {
    file = "/mnt/pool/Library/Software/Operating Systems/Releases/Windows/Client/11/Win11_22H2_EnglishInternational_x64v1.iso"
  }

  disk {
    url = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.229-1/virtio-win-0.1.229.iso"
  }

  disk {
    scsi = true
    volume_id = libvirt_volume.workstation-w11.id
  }

  network_interface {
    bridge = "vmbr0v10"
  }

  xml {
    xslt = file("${path.module}/xslt/workstation.xsl")
  }
}
