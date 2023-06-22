{ lib, config, inputs, outputs, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      inputs.sops-nix.nixosModules.sops
      ./hardware.nix
      ../common/server.nix
      ../common/addons/webhost.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  # boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  sops.defaultSopsFile = ../../secrets/hermes.sops.yaml
  sops.secrets.domain = { };

  networking = {
    hostName = "hermes"; # Define your hostname.
    domain = builtins.readFile config.sops.secrets.domain.path;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "23.05"; # Did you read the comment?
}

