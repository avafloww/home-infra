resource "libvirt_cloudinit_disk" "libvirt_vm_cloudinit" {
  for_each = var.libvirt_vm
  name = "cloudinit_${each.key}.iso"
  user_data = templatefile("${path.module}/cloud-init.tmpl.yml", {
    hostname = each.value.hostname != null ? each.value.hostname : each.key,
    domain = each.value.domain
  })

  network_config = jsonencode({
    version: 2,
    ethernets: {
      ens3: {
        dhcp4: false,
        dhcp6: false,
        addresses: [
          "${each.value.ip_address}/24"
        ],
        gateway4: "10.69.${each.value.net_vlan}.1",
        nameservers: {
          addresses: [
            "10.69.${each.value.net_vlan}.1"
          ]
        }
      }
    }
  })
}

resource "libvirt_volume" "libvirt_vm_disk" {
  for_each = var.libvirt_vm

  name = "${each.key}.qcow2"
  base_volume_id = libvirt_volume.base_image[each.value.os_image].id
  size = each.value.disk_gb * 1024 * 1024 * 1024 # GB to bytes
  pool = libvirt_pool.default.name
}

resource "libvirt_domain" "libvirt_vm_domain" {
  for_each = var.libvirt_vm

  name = each.key
  memory = each.value.memory_gb * 1024 # GB to MB
  vcpu = each.value.cpus
  autostart = each.value.autostart

  cloudinit = libvirt_cloudinit_disk.libvirt_vm_cloudinit[each.key].id

  cpu {
    mode = "host-passthrough"
  }

  boot_device {
    dev = ["hd"]
  }

  disk {
    scsi = true
    volume_id = libvirt_volume.libvirt_vm_disk[each.key].id
  }

  network_interface {
    bridge = "vmbr0v${each.value.net_vlan}"
    hostname = each.value.hostname != null ? each.value.hostname : each.key
    addresses = [
      "${each.value.ip_address}/24"
    ]
  }

  console {
    type = "pty"
    target_port = "0"
    target_type = "serial"
  }

  lifecycle {
    ignore_changes = [
      disk,
      network_interface.0.addresses,
      cloudinit
    ]
  }
}
