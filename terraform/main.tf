provider "hcloud" {
  token = var.hcloud_token
}

provider "hetznerdns" {
  apitoken = var.hetznerdns_token
}

resource "hcloud_ssh_key" "docker-setup" {
  name       = "docker-setup"
  public_key = file("./ssh.pub")
}

resource "hcloud_server" "docker-setup" {
  name        = "docker-setup"
  location    = "nbg1"
  server_type = "cx41"
  image       = "ubuntu-22.04"
  ssh_keys    = [
    hcloud_ssh_key.docker-setup.name
  ]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  labels = {
    "purpose" : "docker-setup"
  }
}

data "hetznerdns_zone" "inmylab" {
  name = "inmylab.de"
}

resource "hetznerdns_record" "docker-setup" {
  zone_id = data.hetznerdns_zone.inmylab.id
  name = "docker-setup"
  value = hcloud_server.docker-setup.ipv4_address
  type = "A"
  ttl= 120
}

resource "hetznerdns_record" "wildcard-docker-setup" {
  zone_id = data.hetznerdns_zone.inmylab.id
  name = "*.docker-setup"
  value = hetznerdns_record.docker-setup.name
  type = "CNAME"
  ttl= 120
}