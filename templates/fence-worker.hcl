provider "nftables" {}

rule "allow_wg0_inbound" {
  provider          = provider.nftables
  direction         = "inbound"
  inbound_interface = "wg0"
  action            = "accept"
  comment           = "Overlay traffic"
}

rule "allow_icmp_inbound" {
  provider  = provider.nftables
  direction = "inbound"
  protocol  = "icmp"
  action    = "accept"
  comment   = "ICMP ping"
}

rule "allow_icmpv6_inbound" {
  provider  = provider.nftables
  direction = "inbound"
  protocol  = "icmpv6"
  action    = "accept"
  comment   = "ICMPv6"
}

rule "allow_bgp_inbound" {
  provider  = provider.nftables
  direction = "inbound"
  protocol  = "tcp"
  dst_port  = ["179"]
  action    = "accept"
  comment   = "BGP peering (BIRD2)"
}

rule "allow_bfd_inbound" {
  provider  = provider.nftables
  direction = "inbound"
  protocol  = "udp"
  dst_port  = ["3784"]
  action    = "accept"
  comment   = "BFD liveness (BIRD2)"
}

rule "allow_http_inbound" {
  provider  = provider.nftables
  direction = "inbound"
  protocol  = "tcp"
  dst_port  = ["80"]
  action    = "accept"
  comment   = "HAProxy frontend"
}

rule "allow_https_inbound" {
  provider  = provider.nftables
  direction = "inbound"
  protocol  = "tcp"
  dst_port  = ["443"]
  action    = "accept"
  comment   = "HAProxy frontend"
}

rule "allow_wireguard_outbound" {
  provider  = provider.nftables
  direction = "outbound"
  protocol  = "udp"
  dst_port  = ["51820"]
  action    = "accept"
  comment   = "WireGuard tunnel"
}

rule "allow_memberlist_outbound" {
  provider  = provider.nftables
  direction = "outbound"
  protocol  = "tcp"
  dst_port  = ["7946"]
  action    = "accept"
  comment   = "Memberlist gossip"
}

rule "allow_dns_udp_outbound" {
  provider  = provider.nftables
  direction = "outbound"
  protocol  = "udp"
  dst_port  = ["53"]
  action    = "accept"
  comment   = "DNS resolution"
}

rule "allow_dns_tcp_outbound" {
  provider  = provider.nftables
  direction = "outbound"
  protocol  = "tcp"
  dst_port  = ["53"]
  action    = "accept"
  comment   = "DNS resolution"
}

rule "allow_https_outbound" {
  provider  = provider.nftables
  direction = "outbound"
  protocol  = "tcp"
  dst_port  = ["443"]
  action    = "accept"
  comment   = "Package updates, API calls"
}

rule "allow_http_outbound" {
  provider  = provider.nftables
  direction = "outbound"
  protocol  = "tcp"
  dst_port  = ["80"]
  action    = "accept"
  comment   = "Package updates"
}

rule "allow_ntp_outbound" {
  provider  = provider.nftables
  direction = "outbound"
  protocol  = "udp"
  dst_port  = ["123"]
  action    = "accept"
  comment   = "Time sync"
}

rule "allow_bgp_outbound" {
  provider  = provider.nftables
  direction = "outbound"
  protocol  = "tcp"
  dst_port  = ["179"]
  action    = "accept"
  comment   = "BGP peering (BIRD2)"
}

rule "allow_bfd_outbound" {
  provider  = provider.nftables
  direction = "outbound"
  protocol  = "udp"
  dst_port  = ["3784"]
  action    = "accept"
  comment   = "BFD liveness (BIRD2)"
}

rule "allow_icmp_outbound" {
  provider  = provider.nftables
  direction = "outbound"
  protocol  = "icmp"
  action    = "accept"
  comment   = "ICMP ping"
}

rule "allow_icmpv6_outbound" {
  provider  = provider.nftables
  direction = "outbound"
  protocol  = "icmpv6"
  action    = "accept"
  comment   = "ICMPv6"
}

rule "allow_forward_from_wg0" {
  provider          = provider.nftables
  direction         = "forward"
  inbound_interface = "wg0"
  action            = "accept"
  comment           = "VM overlay routing"
}

rule "allow_forward_to_wg0" {
  provider           = provider.nftables
  direction          = "forward"
  outbound_interface = "wg0"
  action             = "accept"
  comment            = "VM overlay routing"
}

rule "allow_forward_vm_egress" {
  provider  = provider.nftables
  direction = "forward"
  source    = ["100.64.0.0/10"]
  action    = "accept"
  comment   = "VM internet egress (CGNAT)"
}

interval  = "60s"
log_level = "info"
