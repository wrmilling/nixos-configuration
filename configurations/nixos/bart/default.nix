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
  ];

  modules = {
    machineType.server.enable = true;
    nixos.sshd.banner = "${secrets.sshd.banner}";
    nixos.forgejoRunner = {
      enable = true;
      domain = secrets.forgejo.domain;
      runnerTokenFile = config.sops.secrets."forgejo/runnerToken".path;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Use grub boot loader
  boot.loader.grub.enable = true;
  services.qemuGuest.enable = true;

  networking = {
    hostName = "bart"; # Define your hostname.
    domain = secrets.hosts.common.domain;
    nameservers = secrets.hosts.common.nameservers;
  };

  sops.secrets."forgejo/runnerToken" = {
    sopsFile = ../../../secrets/forgejo.yaml;
  };

  sops.secrets."renovate/token" = {
    sopsFile = ../../../secrets/renovate.yaml;
  };

  sops.secrets."renovate/github_token" = {
    sopsFile = ../../../secrets/renovate.yaml;
  };

  sops.secrets."renovate/git_private_key" = {
    sopsFile = ../../../secrets/renovate.yaml;
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
      packageRules = [
        {
          matchManagers = [ "github-actions" ];
          registryUrls = [ "https://${secrets.forgejo.domain}" ];
        }
      ];
    };
    # Every 10 minutes
    schedule = "*:0/30";
  };

  system.stateVersion = "25.11";
}
