{ config, pkgs, ... }:

let secrets = import ./secrets.nix; in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware.nix
      ../../profiles/server.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  networking = {
    hostName = "hermes"; # Define your hostname.
    domain = secrets.DOMAIN;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "22.11"; # Did you read the comment?
}

