variable "libvirt_host" {
  description = "The libvirt host"
  type = string
}

variable "managed_vms" {
  description = "Managed VM descriptors"
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
