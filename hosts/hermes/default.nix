{ lib, config, pkgs, secrets, ... }:

{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      ./hardware.nix
      ../common/server.nix
      ../common/addons/webhost.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "hermes"; # Define your hostname.
    domain = secrets.hosts.hermes.domain;
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "23.05";
}

