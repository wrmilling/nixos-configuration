{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  cfg = config.modules.nixos.claudeSandbox;
  sandboxLib = import ../../../lib/claude-sandbox.nix { inherit lib; };

  vmName = "claude-sandbox";
  unit = "microvm@${vmName}.service";
in
{
  imports = [ inputs.microvm.nixosModules.host ];

  options.modules.nixos.claudeSandbox = {
    enable = lib.mkEnableOption "Claude Code microVM sandbox";

    vcpu = lib.mkOption {
      type = lib.types.int;
      default = 4;
    };

    memoryMB = lib.mkOption {
      type = lib.types.int;
      default = 4096;
    };

    diskSizeMB = lib.mkOption {
      type = lib.types.int;
      default = 8192;
    };

    workspaceDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/w4cbe/workspace";
    };

    extraShares = lib.mkOption {
      type = lib.types.listOf sandboxLib.shareType;
      default = [ ];
      description = ''
        Extra virtiofs shares into the guest, in addition to the always-present
        workspace share. Each entry maps one host path to one guest mount point.
      '';
    };

    sshForwardPort = lib.mkOption {
      type = lib.types.port;
      default = 2222;
    };

    guestHost = lib.mkOption {
      type = lib.types.str;
      default = "claude-sandbox";
      description = ''
        Which `nixosConfigurations` entry to use as the guest -- the
        x86_64-linux `claude-sandbox` by default, or `claude-sandbox-aarch64`
        on an aarch64-linux host (e.g. a Raspberry Pi or Pinebook) that can
        run it under a native (non-vfkit) hypervisor.
      '';
    };
  };

  config = lib.mkMerge [
    # The microvm host module defaults to enabled once imported, and this
    # component is imported on every host.
    { microvm.host.enable = cfg.enable; }

    (lib.mkIf cfg.enable {
      # microvm.vms.<name>.extraModules doesn't apply to evaluatedConfig, so use
      # extendModules directly on the referenced nixosConfigurations entry.
      microvm.vms.${vmName} = {
        autostart = false;
        evaluatedConfig = outputs.nixosConfigurations.${cfg.guestHost}.extendModules {
          modules = [
            {
              microvm = {
                vcpu = cfg.vcpu;
                mem = cfg.memoryMB;

                interfaces = [
                  {
                    type = "user";
                    id = "vm-nat";
                    mac = "02:00:00:01:01:01";
                  }
                ];

                forwardPorts = [
                  {
                    from = "host";
                    host.address = "127.0.0.1";
                    host.port = cfg.sshForwardPort;
                    guest.port = 22;
                  }
                ];

                volumes = sandboxLib.mkVolumes cfg.diskSizeMB;

                shares = sandboxLib.mkShares { inherit (cfg) workspaceDir extraShares; } ++ [
                  {
                    proto = "virtiofs";
                    tag = "ro-store";
                    source = "/nix/store";
                    mountPoint = "/nix/.ro-store";
                    readOnly = true;
                  }
                ];
              };
            }
          ];
        };
      };

      programs.ssh.extraConfig = ''
        Host ${vmName}
          HostName localhost
          Port ${toString cfg.sshForwardPort}
          User w4cbe
          IdentityFile ${sandboxLib.sshIdentityFile}
          IdentitiesOnly yes
          StrictHostKeyChecking accept-new
          ForwardAgent yes
          RemoteForward ${sandboxLib.guestGpgAgentSocket} ''${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.extra
      '';

      # Let wheel members start/stop/restart the sandbox VM without a sudo password prompt.
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              action.lookup("unit") == "${unit}" &&
              subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';

      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = vmName;
          runtimeInputs = [
            pkgs.openssh
            pkgs.systemd
          ];
          text = ''
            systemctl start "${unit}"

            for _ in $(seq 1 30); do
              if ssh -o ConnectTimeout=1 -o BatchMode=yes ${vmName} true 2>/dev/null; then
                break
              fi
              sleep 1
            done

            dir=''${1:-workspace}
            exec ssh -t ${vmName} "cd \"$dir\" && exec herdr"
          '';
        })
      ];
    })
  ];
}
