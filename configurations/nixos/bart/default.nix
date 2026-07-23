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
      platform = "forgejo";
      autodiscover = true;
      packageRules = [
        {
          # Aliased action names the built-in manager can't resolve; handled by customManagers below.
          matchManagers = [ "github-actions" ];
          matchDepNames = [
            "actions/ssh-agent"
            "actions/setup-qemu-action"
            "actions/setup-buildx-action"
            "actions/docker-login-action"
            "actions/docker-build-push-action"
          ];
          enabled = false;
        }
        {
          # Local action mirrors only sync every 48h; don't suggest a release before the mirror can have it.
          matchDatasources = [ "github-tags" ];
          minimumReleaseAge = "48 hours";
        }
      ];
      customManagers =
        let
          mirroredActions = [
            {
              alias = "actions/ssh-agent";
              upstream = "webfactory/ssh-agent";
            }
            {
              alias = "actions/setup-qemu-action";
              upstream = "docker/setup-qemu-action";
            }
            {
              alias = "actions/setup-buildx-action";
              upstream = "docker/setup-buildx-action";
            }
            {
              alias = "actions/docker-login-action";
              upstream = "docker/login-action";
            }
            {
              alias = "actions/docker-build-push-action";
              upstream = "docker/build-push-action";
            }
            {
              alias = "actions/cache-nix-action";
              upstream = "nix-community/cache-nix-action";
            }
          ];
        in
        map (a: {
          customType = "regex";
          managerFilePatterns = [ "/\\.forgejo/workflows/.*\\.ya?ml$/" ];
          matchStrings = [
            "uses:\\s+${a.alias}@(?<currentDigest>[a-f0-9]{40})\\s*#\\s*(?<currentValue>v[0-9.]+)"
          ];
          depNameTemplate = a.upstream;
          packageNameTemplate = a.upstream;
          datasourceTemplate = "github-tags";
          versioningTemplate = "semver";
        }) mirroredActions;
    };
    # Every 10 minutes
    schedule = "*:0/30";
  };

  system.stateVersion = "25.11";
}
