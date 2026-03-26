provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = "${vars.ovh_application_key}"
  application_secret = "${vars.ovh_application_secret}"
  consumer_key       = "${vars.ovh_consumer_key}"
}

data "ovh_ips" "servers" {}

rule "allow_wireguard_inbound" {
  provider  = provider.nftables
  direction = "inbound"
  protocol  = "udp"
  dst_port  = ["51820"]
  source    = [data.ovh_ips.servers]
  action    = "accept"
  comment   = "WireGuard tunnel (fleet only)"
}

rule "allow_memberlist_inbound" {
  provider  = provider.nftables
  direction = "inbound"
  protocol  = "tcp"
  dst_port  = ["7946"]
  source    = [data.ovh_ips.servers]
  action    = "accept"
  comment   = "Memberlist gossip (fleet only)"
}