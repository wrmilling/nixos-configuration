{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      <nixos-hardware/lenovo/legion/15ich>
      ./hardware.nix
      ../../modules/zram.nix
      ../../profiles/laptop.nix
      ../../profiles/i3wm.nix
      ../../modules/k8s.nix
      ../../modules/gaming.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  networking.hostName = "donnager";
  
  system.stateVersion = "22.11"; # Did you read the comment?
}

