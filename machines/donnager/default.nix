{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      <nixos-hardware/lenovo/legion/15ich>
      ./hardware.nix
      ../../profiles/laptop.nix
      ../../addons/development.nix
      ../../addons/gaming.nix
      ../../addons/k8s-utils.nix
      ../../addons/tailscale.nix
      ../../addons/virtualization.nix
      ../../addons/zram.nix

    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  networking.hostName = "donnager";
  
  system.stateVersion = "22.11"; # Did you read the comment?
}

