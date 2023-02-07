{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      <nixos-hardware/lenovo/thinkpad/x220>
      ./hardware.nix
      ../../modules/zram.nix
      ../../profiles/desktop.nix
      ../../profiles/i3wm.nix
      ../../modules/k8s.nix
      ../../modules/gaming.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "donnager";
  
  system.stateVersion = "22.11"; # Did you read the comment?
}

