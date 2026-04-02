; Infrastructure DNS zone — rendered by pigeon-template from mesh peers.
; Reload: unbound-control auth_zone_reload ${file.secrets.vars.domain}
$ORIGIN ${file.secrets.vars.domain}.
$TTL 300

@  IN SOA servers.${file.secrets.vars.domain}. admin.${file.secrets.vars.domain}. (
    1       ; serial
    3600    ; refresh
    900     ; retry
    604800  ; expire
    300     ; minimum
)

; Nameservers (control-plane nodes)
%{ for peer in jsondecode(exec.peers) ~}
%{ if peer.role == "control-plane" ~}
@  IN NS  ${peer.name}.
%{ endif ~}
%{ endfor ~}

; Individual host records
%{ for peer in jsondecode(exec.peers) ~}
${peer.name}.  IN  AAAA  ${peer.overlay_addr}
%{ endfor ~}

; DC group — servers.<dc>.infra.pigeon.as (round-robin)
%{ for peer in jsondecode(exec.peers) ~}
%{ if peer.role == "control-plane" ~}
servers.${peer.datacenter}  IN  AAAA  ${peer.overlay_addr}
%{ endif ~}
%{ endfor ~}

; Global group — servers.infra.pigeon.as (all control-plane nodes)
%{ for peer in jsondecode(exec.peers) ~}
%{ if peer.role == "control-plane" ~}
servers  IN  AAAA  ${peer.overlay_addr}
%{ endif ~}
%{ endfor ~}
