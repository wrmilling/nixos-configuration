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

  # No daemon supervises vfkit, so dtach stands in and its socket is the
  # running check. The vfkit socket is what makes microvm.socket non-null.
  dtachSocket = "${cfg.stateDir}/console.dtach";
  vfkitSocket = "${cfg.stateDir}/vfkit.sock";

  guestHostName = outputs.nixosConfigurations.${cfg.guestHost}.config.networking.hostName;

  # vfkit has no port forwarding, but shared vmnet makes the guest directly
  # reachable at a DHCP address; bootpd keys this file by the guest hostname.
  leaseFile = "/var/db/dhcpd_leases";

  # macOS keeps the agent sockets in ~/.gnupg, not the XDG runtime dir the
  # Linux hosts forward from.
  gpgSocketDir = "${config.system.primaryUserHome}/.gnupg";

  sshBaseArgs = lib.escapeShellArgs [
    "-i"
    (sandboxLib.sshIdentityFileIn config.system.primaryUserHome)
    "-o"
    "IdentitiesOnly=yes"
    "-o"
    "StrictHostKeyChecking=accept-new"
    # Per-sandbox, so recreating the disk image only invalidates this file.
    # Delete it if entry ever fails on a changed host key.
    "-o"
    "UserKnownHostsFile=${cfg.stateDir}/known_hosts"
  ];

  # The same channels the Linux hosts forward: every signature and every git
  # push still round-trips to the host's real agent, so each needs a PIN and a
  # physical touch. The guest holds no key material.
  sshForwardArgs = lib.escapeShellArgs [
    "-R"
    "${sandboxLib.gpgAgentSocket cfg.guestUid}:${gpgSocketDir}/S.gpg-agent.extra"
    "-R"
    "${sandboxLib.sshAgentSocket cfg.guestUid}:${gpgSocketDir}/S.gpg-agent.ssh"
  ];

  # Shared by `stop` and `reset`; no early exit, so reset still deletes when
  # the VM is already stopped. `state` is a vfkit VM-state: "Stop" requests a
  # guest ACPI shutdown, "HardStop" kills the VM process immediately.
  mkStopIfRunning = state: ''
    if [ -S "${dtachSocket}" ]; then
      curl --fail --silent --show-error \
        --unix-socket "${vfkitSocket}" \
        -X POST -H 'Content-Type: application/json' \
        -d '{"state":"${state}"}' \
        http://localhost/vm/state

      for _ in $(seq 1 30); do
        [ -S "${dtachSocket}" ] || break
        sleep 1
      done
    fi
  '';
  stopIfRunning = mkStopIfRunning "Stop";
  stopIfRunningForce = mkStopIfRunning "HardStop";

  # dtach copies the invoking terminal's termios, so without raw mode ISIG
  # stays on and Ctrl+C SIGINTs vfkit instead of reaching the guest.
  consoleScript = pkgs.writeShellScript "agent-sandbox-console" ''
    ${pkgs.coreutils}/bin/stty raw -echo
    exec ${cfg.runner}/bin/microvm-run
  '';
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

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.system.primaryUserHome}/.local/share/agent-sandbox";
      description = ''
        Where the VM's disk image and sockets live. Nothing supervises vfkit, so
        unlike the qemu host there is no systemd WorkingDirectory to anchor
        relative paths -- without this the disk image would be created in
        whatever directory `agent-sandbox` happened to be run from.
      '';
    };

    guestUid = lib.mkOption {
      type = lib.types.int;
      default = 501;
      description = ''
        uid for the guest's user, overriding the Linux hosts' pinned
        `sandboxLib.guestUid`. vfkit passes host uid/gid through virtiofs
        unmapped, so this has to match the macOS account owning the workspace
        or the guest cannot write to it. 501 is macOS's first local user.
      '';
    };

    hostDocker = {
      enable = lib.mkEnableOption ''
        the host's Docker daemon in the guest.

        virtiofs does not proxy AF_UNIX, so the socket cannot simply be shared
        -- this relays it over TCP instead: a launchd agent on the host, and a
        systemd unit in the guest that turns it back into a unix socket at the
        path the docker CLI already looks for.

        This widens the sandbox. The Docker API is root-equivalent on whatever
        runs the daemon, and Rancher Desktop's VM mounts the macOS home
        directory, so the guest can reach host files outside its workspace
        share
      '';

      socketPath = lib.mkOption {
        type = lib.types.str;
        default = "${config.system.primaryUserHome}/.rd/docker.sock";
        description = "Host-side Docker socket to relay. Default is Rancher Desktop's.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 2375;
        description = "TCP port the relay listens on, host side.";
      };

      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "192.168.64.1";
        description = ''
          Address the relay binds to on the host and dials from the guest --
          the host's own address on Apple's shared vmnet, which is the only
          route the guest has back to it. Deliberately not a wildcard, so
          nothing off-machine can reach the daemon.

          Both ends read this one value: an address that disagreed with the
          host's bind would be unreachable however the guest arrived at it.
          Check it with `ifconfig bridge100` on the host, or `ip route` in the
          guest.
        '';
      };
    };

    guestDocker = {
      enable = lib.mkEnableOption ''
        a real Docker daemon running inside the guest itself, instead of
        relaying the host's (see hostDocker). No path back to host-only
        files -- at the cost of a separate image/layer cache from whatever
        the host runs.
      '';
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
              # virtiofs passes the host uid through unmapped, so the guest has to
              # follow it. NixOS rejects <1000 on a normal user, hence isSystemUser.
              users.users.w4cbe = {
                isNormalUser = lib.mkForce false;
                isSystemUser = true;
                uid = lib.mkForce cfg.guestUid;
                group = "users";
                createHome = true;
              };

              # The guest meets the same TLS interception as the host. Inherited,
              # not re-read, so the delimiter repair stays in one place.
              security.pki.certificates = config.security.pki.certificates;
              environment.variables = {
                NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-bundle.crt";
                REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
              };

              # Restrict SSH to the host; iptables backend, so -I ahead of the dport 22 accept.
              networking.firewall.extraCommands = ''
                iptables -I nixos-fw -p tcp --dport 22 ! -s 192.168.64.1 -j DROP
              '';
              networking.firewall.extraStopCommands = ''
                iptables -D nixos-fw -p tcp --dport 22 ! -s 192.168.64.1 -j DROP 2>/dev/null || true
              '';

              microvm = {
                hypervisor = "vfkit";
                vmHostPackages = pkgs;
                vcpu = cfg.vcpu;
                mem = cfg.memoryMB;
                # Enables vfkit's --restful-uri, which is what lets
                # microvm.nix generate a real microvm-shutdown script.
                socket = vfkitSocket;
                interfaces = [ sandboxLib.userInterface ];
                volumes = sandboxLib.mkVolumes {
                  diskSizeMB = cfg.diskSizeMB;
                  dir = cfg.stateDir;
                };
                shares = sandboxLib.mkShares { inherit (cfg) workspaceDir extraShares; };
              };
            }
          ]
          # Binds the CLI's default socket path, so no DOCKER_HOST is needed, and
          # dials the same address the host binds -- both ends read one option.
          ++ lib.optional cfg.hostDocker.enable (
            sandboxLib.mkHostDockerGuestModule {
              address = cfg.hostDocker.listenAddress;
              inherit (cfg.hostDocker) port;
            }
          )
          ++ lib.optional cfg.guestDocker.enable sandboxLib.guestDockerModule;
        }).config.microvm.runner.vfkit;
    }

    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !(cfg.hostDocker.enable && cfg.guestDocker.enable);
          message = "modules.darwin.agentSandbox: hostDocker and guestDocker both bind /run/docker.sock in the guest -- enable only one.";
        }
      ];
    })

    (lib.mkIf (cfg.enable && cfg.hostDocker.enable) {
      launchd.user.agents.agent-sandbox-docker-relay.serviceConfig = {
        ProgramArguments = [
          (lib.getExe pkgs.socat)
          "TCP-LISTEN:${toString cfg.hostDocker.port},bind=${cfg.hostDocker.listenAddress},fork,reuseaddr"
          "UNIX-CONNECT:${cfg.hostDocker.socketPath}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        # The vmnet interface only exists while a VM is running, so the bind
        # fails until the sandbox starts. KeepAlive is the retry loop; throttle
        # it so it isn't a hot one.
        ThrottleInterval = 10;
      };
    })

    (lib.mkIf cfg.enable {
      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = "agent-sandbox";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.curl
            pkgs.dtach
            pkgs.gawk
            pkgs.openssh
          ];
          text = sandboxLib.mkCommandScript {
            name = "agent-sandbox";
            start = ''
              if [ -S "${dtachSocket}" ]; then
                echo "agent-sandbox is already running"
              else
                mkdir -p "${cfg.stateDir}"
                dtach -n "${dtachSocket}" ${consoleScript}
              fi
            '';
            # Not microvm-shutdown: it sends bare JSON where vfkit serves HTTP, so
            # vfkit answers 400. Waits, so stop/start cannot race two processes.
            stop = ''
              if [ ! -S "${dtachSocket}" ]; then
                echo "agent-sandbox is not running"
                exit 0
              fi

              ${stopIfRunning}
            '';
            stopForce = ''
              if [ ! -S "${dtachSocket}" ]; then
                echo "agent-sandbox is not running"
                exit 0
              fi

              ${stopIfRunningForce}
            '';
            status = ''
              if [ -S "${dtachSocket}" ]; then
                echo "running"
              else
                echo "stopped"
                exit 1
              fi
            '';
            # SSH rather than the console, so the session ends when the
            # harness exits -- the same shape as the qemu host. The console
            # stays available for boot and debugging.
            enter = ''
              for _ in $(seq 1 30); do
                [ -S "${dtachSocket}" ] && break
                sleep 1
              done

              mkdir -p "${cfg.stateDir}"

              guest_ip() {
                awk -F= '
                  $1 ~ /^[ \t]*name$/       { name = $2 }
                  $1 ~ /^[ \t]*ip_address$/ { addr = $2 }
                  /^}/ {
                    if (name == "${guestHostName}") found = addr
                    name = ""; addr = ""
                  }
                  END { if (found != "") print found }
                ' ${leaseFile} 2>/dev/null
              }

              address=""
              for _ in $(seq 1 60); do
                candidate=$(guest_ip)
                if [ -n "$candidate" ] &&
                   ssh ${sshBaseArgs} -o ConnectTimeout=1 -o BatchMode=yes "w4cbe@$candidate" true 2>/dev/null; then
                  address="$candidate"
                  break
                fi
                sleep 1
              done

              if [ -z "$address" ]; then
                echo "agent-sandbox: no SSH route to the guest." >&2
                echo "  It may still be booting, or it never took a DHCP lease." >&2
                echo "  Watch the console with: dtach -a ${dtachSocket} -r winch" >&2
                exit 1
              fi

              exec ssh ${sshBaseArgs} ${sshForwardArgs} -t "w4cbe@$address" herdr
            '';
            # known_hosts goes too: a new image means a new guest host key.
            reset = ''
              ${stopIfRunning}
              rm -f "${cfg.stateDir}/${sandboxLib.imageName}" "${cfg.stateDir}/known_hosts"
              echo "agent-sandbox reset; the disk image is recreated on next start."
            '';
          };
        })
      ];
    })
  ];
}
