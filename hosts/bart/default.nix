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
    domain = secrets.hosts.common.domain;
    nameservers = secrets.hosts.common.nameservers;
    interfaces.eth0 = {
      ipv4.addresses = [{
        address = secrets.hosts.bart.ipAddress;
        prefixLength = secrets.hosts.bart.prefixLength;
      }];
    };
    defaultGateway = {
      address = secrets.hosts.bart.gateway;
      interface = "eth0";
    };
  };

  sops.secrets."forgejo/runnerToken" = {
    sopsFile = ../../secrets/forgejo.yaml;
  };

  sops.secrets."renovate/token" = {
    sopsFile = ../../secrets/renovate.yaml;
  };

  sops.secrets."renovate/github_token" = {
    sopsFile = ../../secrets/renovate.yaml;
  };

  sops.secrets."renovate/git_private_key" = {
    sopsFile = ../../secrets/renovate.yaml;
  };

  virtualisation.docker.enable = true;
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.bart = {
      enable = true;
      name = "bart";
      settings = {
        runner.fetch_interval = "15s";
        container.docker_host = "automount";
      };
      labels = [
        "alpine:docker://alpine:3.22.2"
        "alpine-latest:docker://alpine:latest"
        "alpine-tokyo:docker://${secrets.forgejo.domain}/wrmilling/alpine-tokyo:3.22.2-2"
        "alpine-tokyo-latest:docker://${secrets.forgejo.domain}/wrmilling/alpine-tokyo:latest"
        "ubuntu-latest:docker://node:18-bullseye"
      ];
      url = "https://${secrets.forgejo.domain}";
      tokenFile = config.sops.secrets."forgejo/runnerToken".path;
    };
  };

  services.renovate = {
    enable = true;
    package = pkgs.renovate;
    credentials = {
      # Manually placed on machine
      RENOVATE_TOKEN = config.sops.secrets."renovate/token".path;
      RENOVATE_GITHUB_COM_TOKEN = config.sops.secrets."renovate/github_token".path;
      RENOVATE_GIT_PRIVATE_KEY = config.sops.secrets."renovate/git_private_key".path;
    };
    runtimePackages = [
      pkgs.gnupg
    ];
    settings = {
      endpoint = "https://${secrets.forgejo.domain}";
      gitAuthor = "Renovate Bot <${secrets.forgejo.renovateEmail}>";
      platform = "gitea";
      autodiscover = true;
    };
    # Every 10 minutes
    schedule = "*:0/30";
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
