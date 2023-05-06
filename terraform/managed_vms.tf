resource "libvirt_volume" "managed_disk" {
  for_each = {
    for vm in var.managed_vms : vm.name => vm
  }

  name = "${each.value.name}.qcow2"
  pool = libvirt_pool.default.name
  size = each.value.disk_gb * 1024 * 1024 * 1024 # GB to bytes
  format = "qcow2"
}

resource "libvirt_domain" "managed_vm" {
  for_each = {
    for vm in var.managed_vms : vm.name => vm
  }

  name = each.value.name
  memory = each.value.mem_gb * 1024 # GB to MB

  vcpu = each.value.cpus
  cpu {
    mode = "host-passthrough"
  }

  machine = "q35"
  autostart = false
  running = contains(var.running_vms, each.value.name)

  boot_device {
    dev = ["hd"]
  }

  firmware = each.value.is_windows ? "/usr/share/OVMF/OVMF_CODE_4M.ms.fd" : "/usr/share/OVMF/OVMF_CODE_4M.fd"
  nvram {
    file = "/var/lib/libvirt/qemu/nvram/${each.value.name}_VARS.fd"
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
    xslt = file("${path.module}/xslt/generated/${each.value.name}.xsl")
  }
}

# sleep a bit between each VM to allow QEMU to properly shut down and release PCI devices
# this is needed because the libvirt provider starts the domain at creation to initialize values
resource "null_resource" "sleep" {
  for_each = {
    for vm in var.managed_vms : vm.name => vm
  }

  triggers = {
    name = each.value.name,
    xslt = file("${path.module}/xslt/generated/${each.value.name}.xsl")
  }

  depends_on = [
    libvirt_domain.managed_vm
  ]

  provisioner "local-exec" {
    command = "sleep 10"
  }
}
