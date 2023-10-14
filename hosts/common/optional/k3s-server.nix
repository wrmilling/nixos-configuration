{ config, pkgs, lib, ... }:
let
  secrets = import ../../../secrets/secrets.nix;
  hostname = config.networking.hostName;
  domain = config.networking.domain;
  k3s-package = pkgs.unstable.k3s;
in
{
  # This is required so that pod can reach the API server (running on port 6443 by default) and Metrics (10250)
  networking.firewall.allowedTCPPorts = [ 443 6443 10250 ];
  services.k3s = {
    enable = true;
    package = k3s-package;
    role = "server";
    token = lib.mkDefault secrets.k3s.agent.nodeToken;
    extraFlags = "--tls-san ${hostname}.${domain} --disable servicelb --disable traefik --disable local-storage --flannel-backend=host-gw --node-taint \"node-role.kubernetes.io/master=true:NoSchedule\" --node-label \"k3s-upgrade=false\"";
  };

  environment.systemPackages = [ k3s-package ];
}