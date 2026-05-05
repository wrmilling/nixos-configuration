{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.nixbuild-client;
  nixbuildHost = "bob.${config.networking.domain}";
  nixbuildSupportedFeatures = [
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
    "gccarch-armv8-a"
  ];
in
{
  options.modules.nixos.nixbuild-client = {
    enable = lib.mkEnableOption "nixbuild client packages / settings";

    sshKeyPath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixbuild/nixbuild-client";
      description = "Path to the SSH private key used for the nixbuild remote builder";
      example = "/run/secrets/nixbuild/client-ssh-key";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh.knownHosts = {
      nixbuild = {
        hostNames = [ nixbuildHost ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIoeugUxFnpQMH50+dpEX2x8YAgw0KfBSzcXoD0fdZmp nixbuild-host";
      };
    };

    nix = {
      distributedBuilds = true;
      settings.builders-use-substitutes = true;
      buildMachines = [
        {
          hostName = nixbuildHost;
          protocol = "ssh-ng";
          sshUser = "nixbuild";
          sshKey = cfg.sshKeyPath;
          system = "aarch64-linux";
          maxJobs = 4;
          supportedFeatures = nixbuildSupportedFeatures;
        }
      ];
    };
  };
}
