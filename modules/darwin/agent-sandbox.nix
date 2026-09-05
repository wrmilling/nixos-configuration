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

  # vfkit's console is the microvm-run process's own stdio, with no daemon
  # supervising it -- dtach stands in for that, and its socket doubles as our
  # "is it running" check. The vfkit socket is separate: it's what makes
  # `microvm.socket != null` true, which is what gets microvm.nix to generate
  # a real microvm-shutdown script instead of just a foreground process to kill.
  dtachSocket = "/tmp/agent-sandbox-console.dtach";
  vfkitSocket = "/tmp/agent-sandbox-vfkit.sock";
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
                # Enables vfkit's --restful-uri, which is what lets
                # microvm.nix generate a real microvm-shutdown script.
                socket = vfkitSocket;
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
          runtimeInputs = [ pkgs.dtach ];
          text = sandboxLib.mkCommandScript {
            name = "agent-sandbox";
            start = ''
              if [ -S "${dtachSocket}" ]; then
                echo "agent-sandbox is already running"
              else
                dtach -n "${dtachSocket}" ${cfg.runner}/bin/microvm-run
              fi
            '';
            stop = "${cfg.runner}/bin/microvm-shutdown";
            status = ''
              if [ -S "${dtachSocket}" ]; then
                echo "running"
              else
                echo "stopped"
                exit 1
              fi
            '';
            enter = ''
              for _ in $(seq 1 30); do
                [ -S "${dtachSocket}" ] && break
                sleep 1
              done
              echo 'Attached to the sandbox console. Ctrl+\ detaches without stopping the VM.' >&2
              exec dtach -a "${dtachSocket}" -r winch
            '';
          };
        })
      ];
    })
  ];
}
