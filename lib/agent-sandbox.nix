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
  sshIdentityFile = "~/.config/sops-nix/secrets/${sshSecretName}";

  # RemoteForward expands no tokens for the remote path, so the guest uid is
  # pinned to keep its gpg-agent socket paths predictable.
  guestUid = 1000;
  guestGpgAgentSocket = "/run/user/${toString guestUid}/gnupg/S.gpg-agent";
  guestSshAgentSocket = "/run/user/${toString guestUid}/gnupg/S.gpg-agent.ssh";

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

  mkVolumes = diskSizeMB: [
    {
      image = "agent-sandbox.img";
      mountPoint = "/";
      size = diskSizeMB;
    }
  ];

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
