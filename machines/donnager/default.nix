{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ../../hardware/lenovo/legion/15ich
      ./hardware.nix
      ../../profiles/desktop.nix
      ../../profiles/i3wm.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "donnager";
  networking.networkmanager.enable = true;
  
  system.stateVersion = "22.11"; # Did you read the comment?
}

