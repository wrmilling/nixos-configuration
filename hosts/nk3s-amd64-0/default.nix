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
    ../common/server.nix
    ../common/optional/k3s-server.nix
    ../common/optional/reboot-required.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  networking = {
    hostName = "nk3s-amd64-0";
    domain = secrets.hosts.nk3s-amd64-0.domain;
    useDHCP = lib.mkDefault false;
    interfaces = {
      ens3.ipv4.addresses = [
        {
          address = secrets.hosts.nk3s-amd64-0.address;
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = secrets.hosts.nk3s-amd64-0.defaultGateway;
    nameservers = secrets.hosts.nk3s-amd64-0.nameservers;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "23.11";
}
