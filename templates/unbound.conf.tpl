server:
    interface: 0.0.0.0
    interface: ::0
    port: 53
    username: "unbound"

    access-control: 0.0.0.0/0 allow
    access-control: ::/0 allow

    hide-identity: yes
    hide-version: yes

    num-threads: 2
    msg-cache-size: 16m
    rrset-cache-size: 32m

# Authoritative zone for infrastructure DNS.
# Zone file rendered by pigeon-template. Starts empty if file missing.
auth-zone:
    name: "${file.secrets.vars.domain}"
    zonefile: "/etc/unbound/zones/infra.zone"

# Forward .internal to Consul DNS
stub-zone:
    name: "internal"
    stub-addr: 127.0.0.1@8600

# External resolution (no Cloudflare — Quad9 + OpenDNS)
forward-zone:
    name: "."
    forward-addr: 9.9.9.9
    forward-addr: 208.67.222.222

remote-control:
    control-enable: yes
    control-interface: 127.0.0.1
