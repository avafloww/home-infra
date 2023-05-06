variable "libvirt_host" {
  description = "The libvirt host"
  type = string
}

variable "managed_vms" {
  description = "Managed VM descriptors"
  type = list(object({
    name = string
    is_windows = bool
    cpus = number
    mem_gb = number
    disk_gb = number
    net_vlan = number
  }))
}

variable "running_vms" {
  description = "List of actively running VM names"
  type = list(string)
}
