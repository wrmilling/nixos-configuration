{ config, pkgs, lib, ... }:
let
  secrets = import ../../../secrets/secrets.nix;
  hostname = config.networking.hostName;
  domain = config.networking.domain;
  k3s-package = pkgs.unstable.k3s;
in
{
  # Port Requirements:
  # 53 - PiHole (TCP+UDP)
  # 443 - Nginx Ingress (TCP)
  # 1883 - EMQX Listener (TCP)
  # 5353 - Home Assistant Multicast (TCP+UDP)
  # 6443 - KubeApi (TCP)
  # 7472 - MetalLB (TCP+UDP)
  # 7946 - MetalLB (TCP+UDP)
  # 8083 - EMQX WS (TCP)
  # 8084 - EMQX WSS (TCP)
  # 8123 - Home Assistant (TCP+UDP)
  # 8883 - EMQX SSL/TLS (TCP)
  # 9100 - Node Exporter Metrics (TCP)
  # 9617 - PiHole Metrics Exporter
  # 10250 - Metrics Server (TCP)
  # 10254 - MetalLB Metrics (TCP)
  # 12321 - HASS VSCode (TCP)
  networking.firewall.allowedTCPPorts = [ 53 443 1883 5353 6443 7472 7946 8083 8084 8123 8883 9100 9617 10250 10254 12321 ];
  networking.firewall.allowedUDPPorts = [ 53 5353 7472 7946 8123 ];
  services.k3s = {
    enable = true;
    package = k3s-package;
    role = "server";
    token = lib.mkDefault secrets.k3s.agent.nodeToken;
    extraFlags = "--tls-san ${hostname}.${domain} --disable servicelb --disable traefik --disable local-storage --flannel-backend=host-gw --node-taint \"node-role.kubernetes.io/master=true:NoSchedule\" --node-label \"k3s-upgrade=false\"";
  };

  environment.systemPackages = [ k3s-package ];
}