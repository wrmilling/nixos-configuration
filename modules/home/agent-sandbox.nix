{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  cfg = config.modules.homeType.agentSandbox;
  inherit ((import ../../lib/agent-sandbox.nix { inherit lib; })) sessionSync;

  # Matches the paths modules/home/personal.nix's activation scripts copy to,
  # which the host shares into the guest through extraShares.
  zAiKey = "/home/w4cbe/.config/agent-sandbox/z-ai/api-key";
  opencodeGoKey = "/home/w4cbe/.config/agent-sandbox/opencode-go/api-key";

  # herdr keeps no state-change timestamps, so this plugin hook reports $done_at
  # when a pane's agent goes from working/blocked to idle/done.
  herdrDoneAtHook = pkgs.writeShellApplication {
    name = "herdr-done-at-hook";
    runtimeInputs = [
      pkgs.herdr
      pkgs.coreutils
    ];
    # Runs on every agent status change, so it sticks to bash builtins; herdr is
    # forked only when a token changes.
    text = ''
      # rm loads as a bash builtin on first use, since most runs remove nothing.
      # (bash's loadable mkdir -p chmods existing parents, so mkdir stays external.)
      rm() {
        enable -f ${pkgs.runtimeShellPackage}/lib/bash/rm rm
        unset -f rm
        rm "$@"
      }
      shopt -s nullglob
      state=$HERDR_PLUGIN_STATE_DIR
      json=$HERDR_PLUGIN_EVENT_JSON
      pane_re='"pane_id":"([^"]*)"'
      status_re='"agent_status":"([^"]*)"'
      pane="" status=""
      [[ $json =~ $pane_re ]] && pane=''${BASH_REMATCH[1]}
      [[ $json =~ $status_re ]] && status=''${BASH_REMATCH[1]}
      working=$state/working/''${pane//:/_}
      done_file=$state/done/''${pane//:/_}

      report() {
        herdr pane report-metadata "$1" --source agent-done-at "''${@:2}" >/dev/null
      }

      case $HERDR_PLUGIN_EVENT in
        pane.closed)
          if [[ -e $working || -e $done_file ]]; then
            rm -f "$working" "$done_file"
          fi
          ;;
        # Closing a tab or workspace emits no pane.closed, so drop markers of panes that are gone.
        tab.closed | workspace.closed)
          files=("$state"/working/* "$state"/done/*)
          if ((''${#files[@]})); then
            list=$(herdr pane list)
            declare -A live=()
            while [[ $list =~ $pane_re ]]; do
              live[''${BASH_REMATCH[1]//:/_}]=1
              list=''${list#*"''${BASH_REMATCH[0]}"}
            done
            for f in "''${files[@]}"; do
              if [[ -z ''${live[''${f##*/}]:-} ]]; then
                rm -f "$f"
              fi
            done
          fi
          ;;
        pane.agent_status_changed)
          case $status in
            working | blocked)
              [[ -e $done_file ]] && rm -f "$done_file"
              if [[ ! -e $working ]]; then
                [[ -d $state/working ]] || mkdir -p "$state/working"
                : >"$working"
                report "$pane" --clear-token done_at
              fi
              ;;
            # rm succeeds for only one of any overlapping hook runs.
            idle | done)
              if [[ -e $working ]] && rm "$working" 2>/dev/null; then
                printf -v shown '%(%a %H:%M)T' "$EPOCHSECONDS"
                report "$pane" --token done_at="$shown"
                # From midnight 7 days on the weekday could be mistaken for this week's.
                printf -v hms '%(%H %M %S)T' "$EPOCHSECONDS"
                read -r h m s <<<"$hms"
                switch_at=$((EPOCHSECONDS - 10#$h * 3600 - 10#$m * 60 - 10#$s + 7 * 86400))
                [[ -d $state/done ]] || mkdir -p "$state/done"
                printf '%s %s %s\n' "$switch_at" "$EPOCHSECONDS" "$pane" >"$done_file"
              fi
              ;;
          esac
          ;;
      esac

      # No event fires on a schedule, so any hook run switches week-old times to a date.
      for f in "$state"/done/*; do
        # Another hook run may have removed it since the glob.
        read -r switch_at finished done_pane <"$f" 2>/dev/null || continue
        if ((EPOCHSECONDS >= switch_at)); then
          printf -v shown '%(%m/%d %H:%M)T' "$finished"
          report "$done_pane" --token done_at="$shown" || true
          rm -f "$f"
        fi
      done
    '';
  };

  # A real file, not a symlink: herdr resolves the manifest path and would
  # otherwise take /nix/store as the plugin root.
  herdrDoneAtPlugin = pkgs.runCommand "herdr-done-at-plugin" { } ''
    mkdir $out
    cp ${
      (pkgs.formats.toml { }).generate "herdr-plugin.toml" {
        id = "local.done-at";
        name = "Done at";
        version = "1.0.0";
        min_herdr_version = "0.9.5";
        platforms = [ "linux" ];
        events =
          map
            (on: {
              inherit on;
              command = [ (lib.getExe herdrDoneAtHook) ];
            })
            [
              "pane.agent_status_changed"
              "pane.closed"
              "tab.closed"
              "workspace.closed"
            ];
      }
    } $out/herdr-plugin.toml
  '';

  # plugin link exits 0 even when the server is not up yet, so check its reply.
  herdrDoneAtLink = pkgs.writeShellApplication {
    name = "herdr-done-at-link";
    runtimeInputs = [
      pkgs.herdr
      pkgs.gnugrep
      pkgs.coreutils
    ];
    text = ''
      for _ in $(seq 30); do
        if herdr plugin link ${herdrDoneAtPlugin} 2>/dev/null | grep -q '"type":"plugin_linked"'; then
          exit 0
        fi
        sleep 1
      done
      echo "herdr-done-at-link: herdr server did not accept the plugin link" >&2
      exit 1
    '';
  };
in
{
  options.modules.homeType.agentSandbox = {
    enable = lib.mkEnableOption "agent sandbox guest home-manager modules";

    providers = {
      z-ai.enable = lib.mkEnableOption ''
        the z.ai provider for every harness in the guest (zclaude, zcodex,
        OpenCode's zai-coding-plan, maki). Requires the host to share its
        z.ai key -- see modules/home/personal.nix.
      '';

      opencode-go.enable = lib.mkEnableOption ''
        the OpenCode Go provider for every harness in the guest (oclaude,
        ocodex, OpenCode's opencode-go, maki). Requires the host to share its
        OpenCode Go key -- see modules/home/personal.nix.
      '';
    };

    sessionSync.profile = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum (lib.attrNames sessionSync.profiles));
      default = null;
      description = ''
        The sessionSync profile (lib/agent-sandbox.nix) whose Claude Code
        sessions this guest syncs through the hub. Set by the host, which also
        shares in the Syncthing identity and folder password.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      modules = {
        home.base.enable = true;
        home.terminal.fish.enable = true;
        home.terminal.general.enable = true;
        home.terminal.git.enable = true;
        home.terminal.gpg.enable = true;
        home.terminal.k8s-utils.enable = true;
        home.terminal.development.enable = true;
        home.terminal.starship.enable = true;
        home.terminal.vim.enable = true;
        home.terminal.claude-code.enable = true;
        home.terminal.codex.enable = true;
        home.terminal.opencode.enable = true;
        home.terminal.maki.enable = true;
      };

      # gpg uses the agent socket forwarded from the host, which holds the
      # smartcard. A local agent would bind that path first.
      services.gpg-agent.enable = lib.mkForce false;

      # An unexpired generation is a GC root, so the guest's nix.gc cannot
      # collect it.
      services.home-manager.autoExpire = {
        enable = true;
        frequency = "weekly";
      };

      # Supervised so systemd can stop it on shutdown; a foreground process gets
      # killed by the power-off before it flushes pane state to session.json.
      systemd.user.services.herdr = {
        Unit.Description = "Herdr headless server";
        Install.WantedBy = [ "default.target" ];
        Service = {
          ExecStart = "${pkgs.herdr}/bin/herdr server";
          ExecStop = "${pkgs.herdr}/bin/herdr server stop";
          WorkingDirectory = "/home/w4cbe/workspace";
          Restart = "on-failure";
        };
      };

      # plugins.json is herdr's own registry, so the plugin is linked through its CLI.
      systemd.user.services.herdr-done-at = {
        Unit = {
          Description = "Link the herdr plugin that reports when each agent finished";
          After = [ "herdr.service" ];
          PartOf = [ "herdr.service" ];
        };
        Install.WantedBy = [ "herdr.service" ];
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe herdrDoneAtLink;
        };
      };

      # The sidebar layout is read from the client's config, which runs here over ssh.
      xdg.configFile."herdr/config.toml" = {
        force = true;
        source = (pkgs.formats.toml { }).generate "herdr-config.toml" {
          onboarding = false;
          ui.sidebar.agents.rows = [
            [
              "state_icon"
              "machine"
              "workspace"
              "tab"
            ]
            [
              "agent"
              "$done_at"
            ]
          ];
        };
      };
    })

    (lib.mkIf (cfg.sessionSync.profile != null) (
      let
        profile = sessionSync.profiles.${cfg.sessionSync.profile};
        hubAddress = "${sessionSync.hub.name}.${secrets.hosts.common.domain}:${toString sessionSync.port}";
      in
      {
        services.syncthing = {
          enable = true;
          cert = "${sessionSync.guestDir}/cert.pem";
          key = "${sessionSync.guestDir}/key.pem";
          settings = {
            options = {
              localAnnounceEnabled = false;
              urAccepted = -1;
            };
            devices.${sessionSync.hub.name} = {
              inherit (sessionSync.hub) id;
              addresses = [
                "tcp://${hubAddress}"
                "quic://${hubAddress}"
                "dynamic"
              ];
            };
            folders.${profile.folderId} = {
              id = profile.folderId;
              path = "~/.claude";
              devices = [
                {
                  inherit (sessionSync.hub) name;
                  encryptionPasswordFile = "${sessionSync.guestDir}/password";
                }
              ];
              inherit (sessionSync) ignorePatterns;
              # Guest-local undo for deletes and overwrites arriving from the other sandbox.
              versioning = {
                type = "trashcan";
                params.cleanoutDays = "30";
              };
            };
          };
        };
      }
    ))

    (lib.mkIf cfg.providers.z-ai.enable {
      modules.home.terminal = {
        claude-code.providers.z-ai.apiKeyFile = zAiKey;
        codex.providers.z-ai.apiKeyFile = zAiKey;
        opencode.providers.z-ai.apiKeyFile = zAiKey;
        maki.providers.z-ai.apiKeyFile = zAiKey;
      };
    })

    (lib.mkIf cfg.providers.opencode-go.enable {
      modules.home.terminal = {
        claude-code.providers.opencode-go.apiKeyFile = opencodeGoKey;
        codex.providers.opencode-go.apiKeyFile = opencodeGoKey;
        opencode.providers.opencode-go.apiKeyFile = opencodeGoKey;
        maki.providers.opencode-go.apiKeyFile = opencodeGoKey;
      };
    })
  ];
}
