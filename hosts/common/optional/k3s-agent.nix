{
  config,
  pkgs,
  lib,
  ...
}:
let
  secrets = import ../../../secrets/secrets.nix;
  k3s-package = pkgs.k3s_1_34;
in
{
  imports = [ ./k3s-firewall.nix ];

  sops.secrets."k3s/agent/nodeTokenFull" = {
    sopsFile = ../../../secrets/k3s.yaml;
  };

  services.k3s = {
    enable = true;
    package = k3s-package;
    role = "agent";
    serverAddr = lib.mkDefault secrets.k3s.server.addr;
    tokenFile = config.sops.secrets."k3s/agent/nodeTokenFull".path;
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
