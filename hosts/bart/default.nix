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
    hostName = "bart"; # Define your hostname.
    domain = secrets.hosts.bart.domain;
    nameservers = secrets.hosts.bart.nameservers;
  };

  virtualisation.docker.enable = true;
  services.gitea-actions-runner = {
    package = pkgs.forgejo-actions-runner;
    instances.bart = {
      enable = true;
      name = "bart";
      settings = {
        runner.fetch_interval = "15s";
        container.docker_host = "automount";
      };
      labels = [
        "alpine:docker://alpine:3.21.3"
        "alpine-latest:docker://alpine:latest"
        "alpine-tokyo:docker://${secrets.forgejo.domain}/wrmilling/alpine-tokyo:3.21.3-1"
        "alpine-tokyo-latest:docker://${secrets.forgejo.domain}/wrmilling/alpine-tokyo:latest"
        "ubuntu-latest:docker://node:18-bullseye"
      ];
      url = "https://${secrets.forgejo.domain}";
      token = secrets.forgejo.runnerToken;
    };
  };

  services.renovate = {
    enable = true;
    package = pkgs.renovate;
    credentials = {
      # Manually placed on machine
      RENOVATE_TOKEN = "/etc/renovate/token";
      RENOVATE_GITHUB_COM_TOKEN = "/etc/renovate/github_token";
      RENOVATE_GIT_PRIVATE_KEY = "/etc/renovate/private.key";
    };
    runtimePackages = {
      pkgs.gnupg
    };
    settings = {
      endpoint = "https://${secrets.forgejo.domain}";
      gitAuthor = secrets.forgejo.renovateEmail;
      platform = "gitea";
      autodiscover = true;
    };
    # Every 10 minutes
    schedule = "*:0/10";
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
