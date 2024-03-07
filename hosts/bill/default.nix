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
    # ../common/optional/webhost.nix
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
      labels = [
        "alpine:docker://alpine:3.19.0"
        "alpine-latest:docker://alpine:latest"
        "alpine-tokyo:docker://${secrets.forgejo.domain}/wrmilling/alpine-tokyo:latest"
        "ubuntu-latest:docker://node:18-bullseye"
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
