{
  config,
  inputs,
  outputs,
  pkgs,
  lib,
  secrets,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
    ../common/server.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use grub boot loader
  boot.loader.grub.enable = true;

  networking = {
    hostName = "bill"; # Define your hostname.
    domain = secrets.hosts.bill.domain;
    nameservers = secrets.hosts.bill.nameservers;
  };

  virtualisation.docker.enable = true;
  services.gitea-actions-runner = {
    package = pkgs.forgejo-actions-runner;
    instances.bill = {
      enable = true;
      name = "bill";
      settings = {
        runner.fetch_interval = "15s";
        container.docker_host = "automount";
      };
      labels = [
        "alpine:docker://alpine:3.20.2"
        "alpine-latest:docker://alpine:latest"
        "alpine-tokyo:docker://${secrets.forgejo.domain}/wrmilling/alpine-tokyo:3.21.0-1"
        "alpine-tokyo-latest:docker://${secrets.forgejo.domain}/wrmilling/alpine-tokyo:latest"
        "ubuntu-latest:docker://node:18-bullseye"
      ];
      url = "https://${secrets.forgejo.domain}";
      token = secrets.forgejo.runnerToken;
    };
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "24.11";
}
