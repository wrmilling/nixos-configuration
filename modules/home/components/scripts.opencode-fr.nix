{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.scripts.opencode-fr;

  # Pick an OpenCode session and resume it via opencode with the opencode-go
  # provider pre-selected as the default model. OpenCode restores the original
  # session's model on resume; --model is only a hint if the saved model is
  # unavailable in the configured provider set.
  oofrPackage = pkgs.writeShellApplication {
    name = "oofr";
    runtimeInputs = [
      pkgs.fast-resume
      pkgs.jq
      pkgs.fzf
      pkgs.coreutils
    ];
    text = ''
      if ! command -v opencode >/dev/null 2>&1; then
        echo "oofr: opencode not found on PATH. Enable modules.home.terminal.opencode.opencodeGoApiKeyFile." >&2
        exit 1
      fi

      if { [ "$#" -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
        cat <<'EOF'
      usage: oofr [fr-args...]

      Pick an OpenCode session and resume it with the opencode-go provider
      pre-selected.

      Forwards arguments to `fr --json`, lets you pick a session through fzf,
      then execs `opencode --model opencode-go/glm-5.3 -s <id>` for the chosen
      session. Defaults to `-a opencode` when no agent filter is given.

      Examples:
        oofr                       # pick from recent OpenCode sessions
        oofr "auth bug"            # search and pick
        oofr -d /work/backend      # filter by directory
      EOF
        exit 0
      fi

      has_agent=0
      for arg in "$@"; do
        case "$arg" in
          -a|--agent|-a=*|--agent=*|-a*|agent:*) has_agent=1 ;;
        esac
      done
      if [ "$has_agent" -eq 0 ]; then
        set -- -a opencode "$@"
      fi

      if ! json=$(fr --json --all "$@"); then
        echo "oofr: fr failed" >&2
        exit 1
      fi

      count=$(printf '%s' "$json" | jq -r '.sessions | length // 0')
      if [ "$count" = "0" ]; then
        echo "oofr: no matching sessions" >&2
        exit 1
      fi

      selection=$(printf '%s' "$json" |
        jq -r '.sessions[] | [.id, .timestamp, .directory, .title] | @tsv' |
        fzf --prompt="opencode-go> " \
            --with-nth=2.. \
            --delimiter=$'\t') || exit 0

      [ -n "$selection" ] || exit 0

      id=$(printf '%s' "$selection" | cut -f1)
      exec opencode --model opencode-go/glm-5.3 -s "$id"
    '';
  };

  # Pick an OpenCode session and resume it via opencode with the z.ai provider
  # pre-selected as the default model.
  zofrPackage = pkgs.writeShellApplication {
    name = "zofr";
    runtimeInputs = [
      pkgs.fast-resume
      pkgs.jq
      pkgs.fzf
      pkgs.coreutils
    ];
    text = ''
      if ! command -v opencode >/dev/null 2>&1; then
        echo "zofr: opencode not found on PATH. Enable modules.home.terminal.opencode.zAiApiKeyFile." >&2
        exit 1
      fi

      if { [ "$#" -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
        cat <<'EOF'
      usage: zofr [fr-args...]

      Pick an OpenCode session and resume it with the z.ai provider
      pre-selected.

      Forwards arguments to `fr --json`, lets you pick a session through fzf,
      then execs `opencode --model z-ai/glm-5.3 -s <id>` for the chosen
      session. Defaults to `-a opencode` when no agent filter is given.

      Examples:
        zofr                       # pick from recent OpenCode sessions
        zofr "auth bug"            # search and pick
        zofr -d /work/backend      # filter by directory
      EOF
        exit 0
      fi

      has_agent=0
      for arg in "$@"; do
        case "$arg" in
          -a|--agent|-a=*|--agent=*|-a*|agent:*) has_agent=1 ;;
        esac
      done
      if [ "$has_agent" -eq 0 ]; then
        set -- -a opencode "$@"
      fi

      if ! json=$(fr --json --all "$@"); then
        echo "zofr: fr failed" >&2
        exit 1
      fi

      count=$(printf '%s' "$json" | jq -r '.sessions | length // 0')
      if [ "$count" = "0" ]; then
        echo "zofr: no matching sessions" >&2
        exit 1
      fi

      selection=$(printf '%s' "$json" |
        jq -r '.sessions[] | [.id, .timestamp, .directory, .title] | @tsv' |
        fzf --prompt="z.ai> " \
            --with-nth=2.. \
            --delimiter=$'\t') || exit 0

      [ -n "$selection" ] || exit 0

      id=$(printf '%s' "$selection" | cut -f1)
      exec opencode --model z-ai/glm-5.3 -s "$id"
    '';
  };
in
{
  options.modules.home.scripts.opencode-fr = {
    enable = lib.mkEnableOption "oofr/zofr - resume OpenCode sessions via opencode with provider pre-selected";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      oofrPackage
      zofrPackage
    ];
  };
}
