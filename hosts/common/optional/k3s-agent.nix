{
  config,
  pkgs,
  lib,
  ...
}:
let
  secrets = import ../../../secrets/secrets.nix;
  k3s-package = pkgs.k3s_1_32;
in
{
  imports = [ ./k3s-firewall.nix ];

  services.k3s = {
    enable = true;
    package = k3s-package;
    role = "agent";
    serverAddr = lib.mkDefault secrets.k3s.server.addr;
    token = lib.mkDefault secrets.k3s.agent.nodeToken;
    extraFlags = "--node-label \"k3s-upgrade=false\""; # Optionally add additional args to k3s
    extraKubeletConfig = {
      imageMaximumGCAge = "168h";
    };
  };

  # https://rook.io/docs/rook/latest-release/Getting-Started/Prerequisites/prerequisites/#nixos
  systemd.services.containerd.serviceConfig = {
    LimitNOFILE = lib.mkForce null;
  };

  programs.nbd.enable = true;

  environment.systemPackages = [ k3s-package ];
}
