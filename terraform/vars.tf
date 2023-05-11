variable "libvirt_host" {
  description = "(Ansible generated) The libvirt host"
  type = string
}

variable "managed_vms" {
  description = "(Ansible generated) Managed VM descriptors"
  type = map(object({
    autostart = bool
    is_windows = bool
    iso_url = optional(string)
    cpus = number
    mem_gb = number
    disk_gb = number
    net_vlan = number
  }))
}

variable "libvirt_vm" {
  description = "libvirt VM descriptors"
  type = map(object({
    hostname = optional(string)
    domain = optional(string, "vm.aethernet.ca")
    disk_gb = optional(number, 5)
    memory_gb = number
    cpus = number
    ip_address = string
    net_vlan = number
    os_image = string
    autostart = optional(bool, true)
  }))

  default = {
    "lux-management" = {
      hostname = "lux"
      disk_gb = 10
      memory_gb = 1
      cpus = 2
      ip_address = "10.69.10.99"
      net_vlan = 10
      os_image = "debian11"
    }
  }
}
