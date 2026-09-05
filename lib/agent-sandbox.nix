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
}
