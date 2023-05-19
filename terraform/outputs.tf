output "public_ip4" {
  value = "${hcloud_server.docker-setup.ipv4_address}"
}

output "status" {
  value = "${hcloud_server.docker-setup.status}"
}