{ config, inputs, outputs, pkgs, lib, secrets, ... }:

{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      ./hardware.nix
      ../common/server.nix
    ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "nk3s-amd64-c"; # Define your hostname.
    domain = secrets.hosts.nk3s-amd64-c.domain;
    networkmanager.enable = true;
 };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "23.05";
}