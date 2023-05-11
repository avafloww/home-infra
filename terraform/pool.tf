resource "libvirt_pool" "default" {
  name = "default"
  type = "dir"
  path = "/var/lib/libvirt/images"
}

resource "libvirt_pool" "base_images" {
  name = "base_images"
  type = "dir"
  path = "/var/lib/libvirt/base-images"
}
