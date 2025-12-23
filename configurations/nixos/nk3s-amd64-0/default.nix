{
  config,
  inputs,
  outputs,
  pkgs,
  lib,
  secrets,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  sops.secrets."k3s/agent/nodeTokenFull" = {
    sopsFile = ../../../secrets/k3s.yaml;
  };

  modules = {
    machineType.server.enable = true;
    nixos.sshd.banner = "${secrets.sshd.banner}";
    nixos.rebootRequired.enable = true;
    nixos.k3sServer = {
      enable = true;
      tokenFile = config.sops.secrets."k3s/agent/nodeTokenFull".path;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  networking = {
    hostName = "nk3s-amd64-0";
    domain = secrets.hosts.common-homelab.domain;
    useDHCP = lib.mkDefault false;
    interfaces = {
      ens3.ipv4.addresses = [
        {
          address = secrets.hosts.nk3s-amd64-0.address;
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = secrets.hosts.common-homelab.defaultGateway;
    nameservers = secrets.hosts.common-homelab.nameservers;
  };

  system.stateVersion = "24.11";
}
