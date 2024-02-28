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
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "goku"; # Define your hostname.
    domain = secrets.hosts.goku.domain;
    nameservers = secrets.hosts.goku.nameservers;
    dhcpcd.extraConfig = "nohook resolv.conf";
  };

  virtualisation.docker.enable = true;
  services.gitea-actions-runner = {
    package = pkgs.forgejo-actions-runner;
    instances.goku = {
      enable = true;
      name = "goku";
      labels = [
        "alpine:docker://alpine:3.19.0"
        "alpine-latest:docker://alpine:latest"
        "debian-bullseye:docker://debian:bullseye"
        "debian-bookworm:docker://debian:bookworm"
        "debian-latest:docker://debian:latest"
        "ubuntu-latest:docker://node:18-bullseye"
        "docker:docker://alpine:3.19.0"
      ];
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
