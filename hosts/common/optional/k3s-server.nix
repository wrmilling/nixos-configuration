{
  config,
  pkgs,
  lib,
  ...
}:
let
  secrets = import ../../../secrets/secrets.nix;
  hostname = config.networking.hostName;
  domain = config.networking.domain;
  k3s-package = pkgs.k3s_1_31;
in
{
  imports = [ ./k3s-firewall.nix ];

  services.k3s = {
    enable = true;
    package = k3s-package;
    role = "server";
    token = lib.mkDefault secrets.k3s.agent.nodeToken;
    extraFlags = "--tls-san ${hostname}.${domain} --disable servicelb --disable traefik --disable local-storage --flannel-backend=host-gw --node-taint \"node-role.kubernetes.io/master=true:NoSchedule\" --node-label \"k3s-upgrade=false\"";
  };

  programs.nbd.enable = true;

  environment.systemPackages = [
    k3s-package
    pkgs.kubectl
  ];
}
