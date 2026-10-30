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
  sopsSecretPathIn = home: name: "${home}/.config/sops-nix/secrets/${name}";
  sshIdentityFileIn = home: sopsSecretPathIn home sshSecretName;
  sshIdentityFile = sshIdentityFileIn "~";

  # RemoteForward expands no tokens, so the uid must be known at eval time.
  # The Darwin host renumbers it, hence the socket paths take it as an argument.
  guestUid = 1000;
  imageName = "agent-sandbox.img";
  gpgAgentSocket = uid: "/run/user/${toString uid}/gnupg/S.gpg-agent";
  sshAgentSocket = uid: "/run/user/${toString uid}/gnupg/S.gpg-agent.ssh";

  # Claude Code sessions sync between guests through bob, which holds only the
  # encrypted copy. Device IDs are null until each identity is created with
  # `syncthing generate` and its cert/key added to the matching sops file.
  sessionSync = {
    hub = {
      name = "bob";
      id = "FBHWBCA-CRQD6P3-UB4QCD5-VVNUX3Q-CRUFTML-IW6R3FX-O6F74M2-33FDEA4";
    };
    profiles = {
      personal = {
        folderId = "claude-sessions-personal";
        devices = {
          icarus = "7JOM6J7-DWONIUR-4XSZDWX-6WTULWP-XPADQTK-CFW4AZZ-KEFR6YW-KB4XMQU";
          enterprise = "OIW6Z7B-FVDMXNJ-PX4GTPO-6CAJ32C-CEAZVRO-UHM4UV3-ACXGR4J-SXWIIAF";
        };
      };
      work = {
        folderId = "claude-sessions-work";
        devices.work-mac = "5AWGIKS-45GENV6-M2JWWGY-M4PI3WI-BXMKTON-VUJWSGC-CMRPYPM-DLMOBA4";
      };
    };
    port = 22000;

    # Holds these files, copied out of sops by the host. Each maps to its key in
    # secrets/agent-sandbox-<profile>.yaml and its sops-nix secret name.
    guestDir = "/home/w4cbe/.config/agent-sandbox/syncthing";
    secretKeys = device: {
      "cert.pem" = "syncthing/${device}/cert";
      "key.pem" = "syncthing/${device}/key";
      password = "syncthing/password";
    };
    secretName = file: "agent-sandbox/syncthing/${file}";
    mkShare = source: {
      tag = "syncthing";
      inherit source;
      mountPoint = sessionSync.guestDir;
      readOnly = true;
    };

    # The folder root is ~/.claude; only session state syncs, never credentials.
    ignorePatterns = [
      "!/projects"
      "!/projects/**"
      "!/file-history"
      "!/file-history/**"
      "!/plans"
      "!/plans/**"
      "!/tasks"
      "!/tasks/**"
      "*"
    ];

    mkAssertions =
      {
        option,
        profile,
        device,
      }:
      [
        {
          assertion = sessionSync.hub.id != null;
          message = "${option}: set sessionSync.hub.id in lib/agent-sandbox.nix to bob's Syncthing device ID.";
        }
        {
          assertion = (sessionSync.profiles.${profile}.devices.${device} or null) != null;
          message = "${option}: set sessionSync.profiles.${profile}.devices.${device} in lib/agent-sandbox.nix to this sandbox's Syncthing device ID.";
        }
      ];
  };

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
        image = if dir == null then imageName else "${dir}/${imageName}";
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

  # Guest half of the hostDocker relay. Shared because it is identical however
  # address:port arrives -- only the host-side plumbing differs per platform.
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

  # Body of the script `forward --browse` runs as ssh's LocalCommand, i.e. once
  # the forwards are bound. `launch` is the Chromium command prefix; it must
  # return immediately and outlive the tunnel. One profile per mode, so a
  # profile already running without the proxy is never reused for `socks`.
  mkBrowseScript =
    { launch, profileDir }:
    ''
      url="$1"
      socks_port="''${2:-}"

      if [ -n "$socks_port" ]; then
        profile="${profileDir}/socks"
        set -- --proxy-server="socks5://127.0.0.1:$socks_port" --proxy-bypass-list="<-loopback>"
      else
        profile="${profileDir}/direct"
        set --
      fi

      mkdir -p "$profile"
      ${launch} --user-data-dir="$profile" --no-first-run --no-default-browser-check "$@" "$url" >/dev/null 2>&1 &
    '';

  # Shared CLI shape only; each platform supplies its own snippets, because
  # systemd+ssh and dtach+vfkit mechanics do not unify. `forwardSsh` runs ssh
  # to the guest with "$@" as options, carrying no agent-socket forwards.
  mkCommandScript =
    {
      name,
      start,
      stop,
      stopForce,
      status,
      enter,
      reset,
      isRunning,
      forwardSsh,
      viaSsh,
      browseScript,
      socksPort,
    }:
    ''
      usage() {
        cat <<USAGE
      Usage: ${name} [start|stop [-f|--force]|restart [-f|--force] [-j|--join]|status|forward SPEC... [--browse]|via COMMAND...|reset|help]

        (no args)  Start the sandbox if needed, then enter it.
        start      Start the sandbox without entering it.
        stop       Stop the sandbox. Pass -f/--force to kill it immediately
                   instead of requesting a graceful shutdown.
        restart    Stop the sandbox, then start it again. Pass -f/--force to
                   force-kill it first, and -j/--join to enter it afterward.
        status     Report whether the sandbox is running.
        forward    Forward ports from host loopback into the running sandbox
                   over SSH, in the foreground until Ctrl+C. See '${name} forward -h'.
        via        Run COMMAND in the running sandbox over SSH, with no agent
                   sockets and no prompts. For a Herdr app on this host:
                   hc machine add --name sandbox --via '${name} via'
        reset      Stop the sandbox and delete its disk image. Guest home,
                   credentials and history are lost. Pass -f to skip the prompt.
        help       Show this help.
      USAGE
      }

      forward_usage() {
        cat <<USAGE
      Usage: ${name} forward SPEC... [--browse]

      Forward host loopback ports into the running sandbox over SSH. Runs in the
      foreground until Ctrl+C. Guest services may stay bound to localhost.

        PORT        Forward host 127.0.0.1:PORT to guest localhost:PORT.
        HOST:GUEST  Forward host 127.0.0.1:HOST to guest localhost:GUEST.
        socks       Open a SOCKS proxy on host 127.0.0.1:${toString socksPort} that
                    connects from inside the guest.
        --browse    Open a dedicated Chromium profile once the tunnel is up, at
                    the first forwarded port. With socks, the profile sends every
                    request through the guest, localhost included, so it cannot
                    reach host loopback services; without socks it can.

      Example: ${name} forward 3000 5173 socks --browse
      USAGE
      }

      forward() {
        browse=0
        socks=0
        first_host=""
        first_guest=""
        ssh_args=()

        for spec in "$@"; do
          case "$spec" in
            -h | --help)
              forward_usage
              exit 0
              ;;
            --browse) browse=1 ;;
            socks)
              socks=1
              ssh_args+=(-D "127.0.0.1:${toString socksPort}")
              ;;
            *)
              if [[ ! "$spec" =~ ^([0-9]+)(:([0-9]+))?$ ]]; then
                echo "forward: invalid SPEC: $spec" >&2
                forward_usage >&2
                exit 1
              fi
              host_port=$((10#''${BASH_REMATCH[1]}))
              guest_port=$((10#''${BASH_REMATCH[3]:-''${BASH_REMATCH[1]}}))
              if [ "$host_port" -lt 1024 ] || [ "$host_port" -gt 65535 ] ||
                 [ "$guest_port" -lt 1 ] || [ "$guest_port" -gt 65535 ]; then
                echo "forward: out of range: $spec (host 1024-65535, guest 1-65535)" >&2
                exit 1
              fi
              ssh_args+=(-L "127.0.0.1:$host_port:127.0.0.1:$guest_port")
              first_host=''${first_host:-$host_port}
              first_guest=''${first_guest:-$guest_port}
              ;;
          esac
        done

        if [ "''${#ssh_args[@]}" -eq 0 ]; then
          forward_usage >&2
          exit 1
        fi

        if ! ${isRunning}; then
          echo "${name} is not running; start it first." >&2
          exit 1
        fi

        if [ "$browse" -eq 1 ]; then
          # Through the proxy, localhost is the guest's, so use the guest port.
          if [ "$socks" -eq 1 ]; then
            url=''${first_guest:+http://localhost:$first_guest}
            browse_socks=${toString socksPort}
          else
            url="http://localhost:$first_host"
            browse_socks=""
          fi
          ssh_args+=(
            -o PermitLocalCommand=yes
            -o "LocalCommand=${browseScript} ''${url:-about:blank} $browse_socks"
          )
        fi

        echo "Forwarding; press Ctrl+C to stop."
        forward_ssh -N -a -o ExitOnForwardFailure=yes "''${ssh_args[@]}"
      }

      forward_ssh() {
        ${forwardSsh}
      }

      # Scans the remaining args (not just a fixed position) so stop/restart
      # flags can appear in any order, e.g. `restart -f -j` or `restart -j -f`.
      has_flag() {
        short="$1"
        long="$2"
        shift 2
        for arg in "$@"; do
          if [ "$arg" = "$short" ] || [ "$arg" = "$long" ]; then
            return 0
          fi
        done
        return 1
      }

      case ''${1:-} in
        start)
          ${start}
          ;;
        stop)
          if has_flag -f --force "$@"; then
            ${stopForce}
          else
            ${stop}
          fi
          ;;
        restart)
          if has_flag -f --force "$@"; then
            ${stopForce}
          else
            ${stop}
          fi
          ${start}
          if has_flag -j --join "$@"; then
            ${enter}
          fi
          ;;
        status)
          ${status}
          ;;
        reset)
          if [ "''${2:-}" != "-f" ] && [ "''${2:-}" != "--force" ]; then
            printf 'Delete the sandbox disk image? Guest home, credentials and history are lost. [y/N] '
            read -r reply
            case "$reply" in
              [yY] | [yY][eE][sS]) ;;
              *)
                echo "Aborted." >&2
                exit 1
                ;;
            esac
          fi
          ${reset}
          ;;
        forward)
          shift
          forward "$@"
          ;;
        via)
          shift
          if ! ${isRunning}; then
            echo "${name} is not running; start it first." >&2
            exit 1
          fi
          ${viaSsh}
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
