{
  config,
  pkgs,
  lib,
  ...
}: {
  networking.firewall.allowedTCPPorts = [
    53 # PiHole (TCP+UDP)
    443 # Nginx Ingress (TCP)
    1883 # EMQX Listener (TCP)
    2222 # Forgejo SSH (TCP)
    5353 # Home Assistant Multicast (TCP+UDP)
    6443 # KubeApi (TCP)
    7472 # MetalLB (TCP+UDP)
    7473 # MetalLB FRR (TCP+UDP)
    7946 # MetalLB (TCP+UDP)
    8083 # EMQX WS (TCP)
    8084 # EMQX WSS (TCP)
    8123 # Home Assistant (TCP+UDP)
    8883 # EMQX SSL/TLS (TCP)
    9080 # CSI RBD Plugin Metrics (TCP)
    9090 # CSI RBD Plugin GRPC Metrics (TCP)
    9100 # Node Exporter Metrics (TCP)
    9617 # PiHole Metrics Exporter (TCP)
    10250 # K3s Metrics Server (TCP)
    10254 # MetalLB Metrics Export (TCP)
    12321 # HASS VSCode (TCP)
  ];
  networking.firewall.allowedUDPPorts = [
    53 # PiHole (TCP+UDP)
    5353 # Home Assistant Multicast (TCP+UDP)
    7472 # MetalLB (TCP+UDP)
    7473 # MetalLB FRR (TCP+UDP)
    7946 # MetalLB (TCP+UDP)
    8123 # Home Assistant (TCP+UDP)
  ];
}
