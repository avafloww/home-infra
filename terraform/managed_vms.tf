resource "libvirt_volume" "managed_disk" {
  for_each = var.managed_vms

  name = "${each.key}.qcow2"
  pool = libvirt_pool.default.name
  size = each.value.disk_gb * 1024 * 1024 * 1024 # GB to bytes
  format = "qcow2"
}

resource "libvirt_domain" "managed_vm" {
  for_each = var.managed_vms

  name = each.key
  memory = each.value.mem_gb * 1024 # GB to MB

  vcpu = each.value.cpus
  cpu {
    mode = "host-passthrough"
  }

  machine = "q35"
  autostart = each.value.autostart
  running = false

  boot_device {
    dev = ["hd"]
  }

  firmware = each.value.is_windows ? "/usr/share/OVMF/OVMF_CODE_4M.ms.fd" : "/usr/share/OVMF/OVMF_CODE_4M.fd"
  nvram {
    file = "/var/lib/libvirt/qemu/nvram/${each.key}_VARS.fd"
    template = each.value.is_windows ? "/usr/share/OVMF/OVMF_VARS_4M.ms.fd" : "/usr/share/OVMF/OVMF_VARS_4M.fd"
  }

  disk {
    scsi = true
    volume_id = libvirt_volume.managed_disk[each.key].id
  }

  network_interface {
    bridge = "vmbr0v${each.value.net_vlan}"
  }

  xml {
    xslt = file("${path.module}/xslt/generated/${each.key}.xsl")
  }

  lifecycle {
    ignore_changes = [
      disk.0.wwn
    ]
  }
}
