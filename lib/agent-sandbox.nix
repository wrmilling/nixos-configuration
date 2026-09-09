{ lib }:
let
  guestWorkspace = "/home/w4cbe/workspace";

  toVirtiofsShare = share: {
    proto = "virtiofs";
    inherit (share)
      tag
      source
      mountPoint
      readOnly
      ;
  };
in
rec {
  # Dedicated keypair for the local sandbox VMs, so logging in does not need a
  # smartcard touch. sops-nix decrypts to ~/.config/sops-nix/secrets/<name>.
  sshSecretName = "sandbox/sshKey";
  # ssh_config expands `~` itself; a shell command line does not, so the Darwin
  # host passes the real home rather than quoting a tilde into oblivion.
  sshIdentityFileIn = home: "${home}/.config/sops-nix/secrets/${sshSecretName}";
  sshIdentityFile = sshIdentityFileIn "~";

  # RemoteForward expands no tokens for the remote path, so the guest uid has
  # to be known at eval time. It is pinned for the Linux hosts, but the Darwin
  # host renumbers the guest to match its own macOS account, so the socket
  # paths take the uid rather than assuming it.
  guestUid = 1000;
  gpgAgentSocket = uid: "/run/user/${toString uid}/gnupg/S.gpg-agent";
  sshAgentSocket = uid: "/run/user/${toString uid}/gnupg/S.gpg-agent.ssh";

  shareType = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.str;
        description = "Path on the host.";
      };
      mountPoint = lib.mkOption {
        type = lib.types.str;
        description = "Path inside the guest.";
      };
      tag = lib.mkOption {
        type = lib.types.str;
        description = "virtiofs tag, must be unique per share.";
      };
      readOnly = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  mkShares =
    {
      workspaceDir,
      extraShares,
    }:
    [
      {
        proto = "virtiofs";
        tag = "workspace";
        source = workspaceDir;
        mountPoint = guestWorkspace;
      }
    ]
    ++ map toVirtiofsShare extraShares;

  # `dir = null` keeps the image path relative, which is what the qemu host
  # wants -- microvm's systemd unit sets WorkingDirectory. vfkit is started by
  # hand from an arbitrary cwd, so the Darwin host passes an absolute dir.
  mkVolumes =
    {
      diskSizeMB,
      dir ? null,
    }:
    [
      {
        image = if dir == null then "agent-sandbox.img" else "${dir}/agent-sandbox.img";
        mountPoint = "/";
        size = diskSizeMB;
      }
    ];

  # User-mode NAT, the only networking both hypervisors implement. qemu adds
  # forwardPorts on top of this; vfkit has no equivalent.
  userInterface = {
    type = "user";
    id = "vm-nat";
    mac = "02:00:00:01:01:01";
  };

  # A real Docker daemon inside the guest -- no relay, no path back to
  # host-only files, at the cost of a separate image/layer cache from
  # whatever the host itself runs.
  guestDockerModule =
    { pkgs, ... }:
    {
      virtualisation.docker.enable = true;
      users.users.w4cbe.extraGroups = [ "docker" ];
      environment.systemPackages = [ pkgs.docker-compose ];
    };

  # The guest-side half of a hostDocker relay: CLI packages plus a unit that
  # turns a TCP connection to `address:port` back into the unix socket the
  # docker CLI already looks for. Shared because it's identical regardless of
  # how `address:port` gets there -- vfkit's shared vmnet on Darwin, qemu's
  # guestfwd on NixOS -- only the host-side plumbing differs.
  mkHostDockerGuestModule =
    { address, port }:
    { pkgs, lib, ... }:
    {
      environment.systemPackages = [
        pkgs.docker-client
        pkgs.docker-compose
      ];
      users.groups.docker = { };
      users.users.w4cbe.extraGroups = [ "docker" ];

      systemd.services.host-docker-relay = {
        description = "Relay the host's Docker socket into the guest";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          ExecStart = lib.concatStringsSep " " [
            (lib.getExe pkgs.socat)
            "UNIX-LISTEN:/run/docker.sock,fork,unlink-early,mode=0660,group=docker"
            "TCP:${address}:${toString port}"
          ];
          Restart = "always";
          RestartSec = 5;
        };
      };
    };

  # Shared CLI shape for the per-platform `agent-sandbox` command. Each
  # platform supplies its own start/stop/status/enter shell snippets -- the
  # underlying mechanics (systemd+ssh vs. dtach+vfkit) don't unify, only the
  # command surface does.
  mkCommandScript =
    {
      name,
      start,
      stop,
      status,
      enter,
    }:
    ''
      usage() {
        cat <<USAGE
      Usage: ${name} [start|stop|status|help]

        (no args)  Start the sandbox if needed, then enter it.
        start      Start the sandbox without entering it.
        stop       Stop the sandbox.
        status     Report whether the sandbox is running.
        help       Show this help.
      USAGE
      }

      case ''${1:-} in
        start)
          ${start}
          ;;
        stop)
          ${stop}
          ;;
        status)
          ${status}
          ;;
        help | -h | --help)
          usage
          ;;
        "")
          ${start}
          ${enter}
          ;;
        *)
          echo "Unknown command: $1" >&2
          usage >&2
          exit 1
          ;;
      esac
    '';
}
