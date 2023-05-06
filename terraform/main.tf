resource "libvirt_pool" "default" {
  name = "default"
  type = "dir"
  path = "/var/lib/libvirt/images"
}
