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
  # https://github.com/NixOS/nixpkgs/pull/405952
  k3s-package = pkgs.k3s_1_33.override {
    util-linux = pkgs.util-linuxMinimal.overrideAttrs (prev: {
      patches = prev.patches or [] ++ [./patches/fix-mount-regression.patch];
    });
  };
in
{
  imports = [ ./k3s-firewall.nix ];

  sops.secrets."k3s/agent/nodeTokenFull" = {
    sopsFile = ../../../secrets/k3s.yaml;
  };

  services.k3s = {
    enable = true;
    package = k3s-package;
    role = "server";
    tokenFile = config.sops.secrets."k3s/agent/nodeTokenFull".path;
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
}
