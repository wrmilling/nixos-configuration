{
  config,
  inputs,
  outputs,
  pkgs,
  lib,
  secrets,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
    ../common/server.nix
    ../common/optional/docker.nix
    ../common/optional/forgejo-actions.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "goku"; # Define your hostname.
    domain = secrets.hosts.goku.domain;
  };

  services.nginx.virtualHosts."${secrets.hosts.goku.domain}" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/${secrets.hosts.goku.domain}";
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "23.11";
}
