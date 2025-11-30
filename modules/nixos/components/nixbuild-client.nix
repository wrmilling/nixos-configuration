{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixbuild-client;
in
{
  options.modules.nixbuild-client = {
    enable = lib.mkEnableOption "nixbuild client packages / settings";
  };

  config = lib.mkIf cfg.enable {
    programs.ssh.extraConfig = ''
      Host nixbuild.${config.networking.domain}
        HostName hermes.${config.networking.domain}
        User nixbuild
        PubkeyAcceptedKeyTypes ssh-ed25519
        IdentityFile /etc/nixbuild/nixbuild-client
    '';

    programs.ssh.knownHosts = {
      nixbuild = {
        hostNames = [ "hermes.${config.networking.domain}" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/hRd7PJ/Qby/nB34LNkOPkwyTsc2eJAyaL0ANH1V+h Hermes.BuildHost";
      };
    };

    nix = {
      distributedBuilds = true;
      buildMachines = [
        {
          hostName = "hermes.${config.networking.domain}";
          system = "aarch64-linux";
          maxJobs = 4;
          supportedFeatures = [ ];
        }
      ];
    };
  };
}