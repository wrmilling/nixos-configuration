{
  config,
  lib,
  pkgs,
  outputs,
  ...
}:
let
  cfg = config.modules.darwin.agentSandbox;
  sandboxLib = import ../../lib/agent-sandbox.nix { inherit lib; };
in
{
  options.modules.darwin.agentSandbox = {
    enable = lib.mkEnableOption "agent sandbox microVM";

    vcpu = lib.mkOption {
      type = lib.types.int;
      default = 4;
    };

    memoryMB = lib.mkOption {
      type = lib.types.int;
      default = 8192;
    };

    diskSizeMB = lib.mkOption {
      type = lib.types.int;
      default = 32768;
    };

    workspaceDir = lib.mkOption {
      type = lib.types.str;
      description = "Host path shared into the guest as its workspace.";
    };

    extraShares = lib.mkOption {
      type = lib.types.listOf sandboxLib.shareType;
      default = [ ];
      description = ''
        Extra virtiofs shares into the guest, in addition to the always-present
        workspace share. Each entry maps one host path to one guest mount point.

        vfkit does not enforce readOnly on virtiofs shares.
      '';
    };

    guestHost = lib.mkOption {
      type = lib.types.str;
      default = "agent-sandbox-aarch64";
      description = "Which `nixosConfigurations` entry to use as the guest.";
    };

    runner = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "The vfkit runner built from the guest configuration.";
    };
  };

  config = lib.mkMerge [
    {
      modules.darwin.agentSandbox.runner =
        (outputs.nixosConfigurations.${cfg.guestHost}.extendModules {
          modules = [
            {
              microvm = {
                hypervisor = "vfkit";
                vmHostPackages = pkgs;
                vcpu = cfg.vcpu;
                mem = cfg.memoryMB;
                volumes = sandboxLib.mkVolumes cfg.diskSizeMB;
                shares = sandboxLib.mkShares { inherit (cfg) workspaceDir extraShares; };
              };
            }
          ];
        }).config.microvm.runner.vfkit;
    }

    (lib.mkIf cfg.enable {
      nix.linux-builder = {
        enable = true;
        systems = [ "aarch64-linux" ];
      };

      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = "agent-sandbox";
          text = ''
            cleanup() { stty "$(stty -g)" 2>/dev/null || true; }
            trap cleanup EXIT
            stty intr ^] susp ^] quit ^] 2>/dev/null || true

            exec ${cfg.runner}/bin/microvm-run
          '';
        })
      ];
    })
  ];
}
