{ config, inputs, outputs, pkgs, lib, secrets, ... }:

{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      ./hardware.nix
      ../common/server.nix
      # ../common/optional/k3s-agent.nix
    ];

  boot.kernelPackages = lib.mkDefault pkgs.linuxKernel.packages.linux_rpi4;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  networking = {
    hostName = "nk3s-arm64-a";
    domain = secrets.hosts.nk3s-arm64-a.domain;
    useDHCP = lib.mkDefault true;
    interfaces = {
      end0.ipv4.addresses = [
        {
          address = secrets.hosts.nk3s-arm64-a.address;
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = secrets.hosts.nk3s-arm64-a.defaultGateway;
    nameservers = secrets.hosts.nk3s-arm64-a.nameservers;
 };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "23.05";
}
