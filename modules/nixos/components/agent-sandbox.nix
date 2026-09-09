{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  cfg = config.modules.nixos.agentSandbox;
  sandboxLib = import ../../../lib/agent-sandbox.nix { inherit lib; };

  vmName = "agent-sandbox";
  unit = "microvm@${vmName}.service";
in
{
  imports = [ inputs.microvm.nixosModules.host ];

  options.modules.nixos.agentSandbox = {
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

    guestDocker = {
      enable = lib.mkEnableOption ''
        a real Docker daemon running inside the guest itself, instead of
        relaying the host's (see hostDocker). No path back to host-only
        files -- at the cost of a separate image/layer cache from whatever
        the host runs.
      '';
    };

    hostDocker = {
      enable = lib.mkEnableOption ''
        the host's Docker daemon in the guest.

        virtiofs does not proxy AF_UNIX, so the socket cannot simply be
        shared. Unlike Darwin's vfkit, this guest has no subnet shared with
        the host to relay over directly -- it sits behind qemu's SLIRP
        user-mode NAT. qemu's `guestfwd` covers the gap instead: a
        connection the guest makes to `guestAddress:port` is intercepted
        inside the qemu process itself and piped to `nc 127.0.0.1 port` on
        the host, with no real network traffic involved. A user unit on
        each side turns that TCP round-trip back into a unix socket.

        This widens the sandbox: the Docker API is root-equivalent on
        whatever runs the host's daemon.
      '';

      socketPath = lib.mkOption {
        type = lib.types.str;
        default = "/run/user/${toString config.users.users.w4cbe.uid}/docker.sock";
        description = "Host-side Docker socket to relay. Default matches dockerRootless's socket.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 2375;
        description = "TCP port used for the guestfwd relay.";
      };

      guestAddress = lib.mkOption {
        type = lib.types.str;
        default = "10.0.2.100";
        description = ''
          Virtual address the guest dials to reach the relay -- qemu's
          guestfwd intercepts traffic addressed here and pipes it to the
          host, rather than anything actually listening at this address.
          Must sit inside the "user" interface's 10.0.2.0/24 VLAN and avoid
          SLIRP's own reserved addresses (.2 gateway, .3 dns, .15 guest
          DHCP lease).
        '';
      };
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
      default = "agent-sandbox";
      description = ''
        Which `nixosConfigurations` entry to use as the guest -- the
        x86_64-linux `agent-sandbox` by default, or `agent-sandbox-aarch64`
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

                # Lets the host reclaim memory the guest isn't using; does not
                # raise the guest's own ceiling (that's memoryMB). vfkit has no
                # equivalent, so this stays qemu-only -- do not move it into
                # guest.nix, which the Darwin module also extends.
                balloon = true;

                interfaces = [ sandboxLib.userInterface ];

                forwardPorts = [
                  {
                    from = "host";
                    host.address = "127.0.0.1";
                    host.port = cfg.sshForwardPort;
                    guest.port = 22;
                  }
                ]
                ++ lib.optional cfg.hostDocker.enable {
                  from = "guest";
                  guest.address = cfg.hostDocker.guestAddress;
                  guest.port = cfg.hostDocker.port;
                  host.address = "127.0.0.1";
                  host.port = cfg.hostDocker.port;
                };

                volumes = sandboxLib.mkVolumes { diskSizeMB = cfg.diskSizeMB; };

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
          ]
          ++ lib.optional cfg.hostDocker.enable (
            sandboxLib.mkHostDockerGuestModule {
              address = cfg.hostDocker.guestAddress;
              inherit (cfg.hostDocker) port;
            }
          )
          ++ lib.optional cfg.guestDocker.enable sandboxLib.guestDockerModule;
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
          RemoteForward ${sandboxLib.gpgAgentSocket sandboxLib.guestUid} ''${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.extra
          RemoteForward ${sandboxLib.sshAgentSocket sandboxLib.guestUid} ''${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh
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

      assertions = [
        {
          assertion = !(cfg.hostDocker.enable && cfg.guestDocker.enable);
          message = "modules.nixos.agentSandbox: hostDocker and guestDocker both bind /run/docker.sock in the guest -- enable only one.";
        }
      ];

      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = vmName;
          runtimeInputs = [
            pkgs.coreutils
            pkgs.openssh
            pkgs.systemd
          ];
          text = sandboxLib.mkCommandScript {
            name = vmName;
            start = ''systemctl start "${unit}"'';
            stop = ''systemctl stop "${unit}"'';
            status = ''
              state=$(systemctl is-active "${unit}" || true)
              echo "$state"
              [ "$state" = "active" ]
            '';
            enter = ''
              for _ in $(seq 1 30); do
                if ssh -o ConnectTimeout=1 -o BatchMode=yes ${vmName} true 2>/dev/null; then
                  break
                fi
                sleep 1
              done

              exec ssh -t ${vmName} herdr
            '';
            # The image is root-owned under microvm's stateDir, so this is the one
            # subcommand that needs sudo; the host key changes with the new image.
            reset = ''
              systemctl stop "${unit}" || true
              ${config.security.wrapperDir}/sudo rm -f "${config.microvm.stateDir}/${vmName}/${sandboxLib.imageName}"
              ssh-keygen -R "[localhost]:${toString cfg.sshForwardPort}" >/dev/null 2>&1 || true
              echo "${vmName} reset; the disk image is recreated on next start."
            '';
          };
        })
      ];
    })

    (lib.mkIf (cfg.enable && cfg.hostDocker.enable) {
      # A user unit, not a system one: the socket it relays belongs to
      # whichever user is running dockerRootless, and the relay has no
      # business running before that user has a session.
      systemd.user.services.agent-sandbox-docker-relay = {
        description = "Relay this user's Docker socket into the agent-sandbox guest";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          # Retries rather than fails outright: the rootless docker socket
          # may not exist yet if the user hasn't started it this session.
          ExecStart = "${lib.getExe pkgs.socat} TCP-LISTEN:${toString cfg.hostDocker.port},bind=127.0.0.1,fork,reuseaddr UNIX-CONNECT:${cfg.hostDocker.socketPath}";
          Restart = "always";
          RestartSec = 5;
        };
      };
    })
  ];
}
