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
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "goku"; # Define your hostname.
    domain = secrets.hosts.goku.domain;
  };

  services.gitea-actions-runner = {
    package = pkgs.unstable.forgejo-actions-runner;
    instances.goku = {
      enable = true;
      name = "goku";
      labels = [];
      url = secrets.forgejo.domain;
      token = secrets.forgejo.runnerToken;
    };
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "23.11";
}
