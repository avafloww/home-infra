locals {
  datestamp = formatdate("YYYYMMDD", timestamp())
  base_images = {
    "debian11" = "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2",
    "ubuntu2204" = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img",
  }
}

resource "libvirt_volume" "base_image" {
  for_each = local.base_images
  name = "${local.datestamp}-${each.key}.qcow2"
  pool = libvirt_pool.base_images.name
  format = "qcow2"
  source = each.value

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      name
    ]
  }
}
