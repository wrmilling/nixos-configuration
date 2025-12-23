{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.k3sServer;
  hostname = config.networking.hostName;
  domain = config.networking.domain;
  k3s-package = pkgs.k3s_1_34;
in
{
  imports = [ ./k3s-firewall.nix ];

  options.modules.nixos.k3sServer = {
    enable = lib.mkEnableOption "k3s server packages / settings";
    tokenFile = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "File path to the node tokenFile secret";
    };
  };

  config = lib.mkIf cfg.enable {
    modules = {
      nixos.k3sFirewall.enable = true;
    };

    services.k3s = {
      enable = true;
      package = k3s-package;
      role = "server";
      tokenFile = config.modules.k3sServer.tokenFile;
      extraFlags = "--tls-san ${hostname}.${domain} --disable servicelb --disable traefik --disable local-storage --flannel-backend=host-gw --node-taint \"node-role.kubernetes.io/master=true:NoSchedule\" --node-label \"k3s-upgrade=false\"";
      extraKubeletConfig = {
        imageMaximumGCAge = "168h";
      };
    };

    programs.nbd.enable = true;

    environment.systemPackages = [
      k3s-package
      pkgs.kubectl
    ];
  };
}