{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.scripts.codex-fr;

  # Pick a Codex session and resume it via ocodex (OpenCode Go endpoint).
  ocodexFr = pkgs.writeShellApplication {
    name = "oxfr";
    runtimeInputs = [
      pkgs.fast-resume
      pkgs.jq
      pkgs.fzf
      pkgs.coreutils
    ];
    text = ''
      if ! command -v ocodex >/dev/null 2>&1; then
        echo "oxfr: ocodex not found on PATH. Enable modules.home.terminal.codex.opencodeGoApiKeyFile." >&2
        exit 1
      fi

      if { [ "$#" -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; }; then
        cat <<'EOF'
      usage: oxfr [fr-args...]

      Pick a Codex session and resume it via ocodex (OpenCode Go endpoint).

      Forwards arguments to `fr --json`, lets you pick a session through fzf,
      then execs `ocodex resume <id>` for the chosen session. Defaults to
      `-a codex` when no agent filter is given.

      Examples:
        oxfr                       # pick from recent Codex sessions
        oxfr "auth bug"            # search and pick
        oxfr -d /work/backend      # filter by directory
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
        set -- -a codex "$@"
      fi

      if ! json=$(fr --json --all "$@"); then
        echo "oxfr: fr failed" >&2
        exit 1
      fi

      count=$(printf '%s' "$json" | jq -r '.sessions | length // 0')
      if [ "$count" = "0" ]; then
        echo "oxfr: no matching sessions" >&2
        exit 1
      fi

      selection=$(printf '%s' "$json" |
        jq -r '.sessions[] | [.id, .timestamp, .directory, .title] | @tsv' |
        fzf --prompt="ocodex> " \
            --with-nth=2.. \
            --delimiter=$'\t') || exit 0

      [ -n "$selection" ] || exit 0

      id=$(printf '%s' "$selection" | cut -f1)
      exec ocodex resume "$id"
    '';
  };

  # Pick a Codex session and resume it via zcodex (z.ai endpoint).
  zcodexFr = pkgs.writeShellApplication {
    name = "zxfr";
    runtimeInputs = [
      pkgs.fast-resume
      pkgs.jq
      pkgs.fzf
      pkgs.coreutils
    ];
    text = ''
      if ! command -v zcodex >/dev/null 2>&1; then
        echo "zxfr: zcodex not found on PATH. Enable modules.home.terminal.codex.zAiApiKeyFile." >&2
        exit 1
      fi

      if { [ "$#" -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; }; then
        cat <<'EOF'
      usage: zxfr [fr-args...]

      Pick a Codex session and resume it via zcodex (z.ai endpoint).

      Forwards arguments to `fr --json`, lets you pick a session through fzf,
      then execs `zcodex resume <id>` for the chosen session. Defaults to
      `-a codex` when no agent filter is given.

      Examples:
        zxfr                       # pick from recent Codex sessions
        zxfr "auth bug"            # search and pick
        zxfr -d /work/backend      # filter by directory
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
        set -- -a codex "$@"
      fi

      if ! json=$(fr --json --all "$@"); then
        echo "zxfr: fr failed" >&2
        exit 1
      fi

      count=$(printf '%s' "$json" | jq -r '.sessions | length // 0')
      if [ "$count" = "0" ]; then
        echo "zxfr: no matching sessions" >&2
        exit 1
      fi

      selection=$(printf '%s' "$json" |
        jq -r '.sessions[] | [.id, .timestamp, .directory, .title] | @tsv' |
        fzf --prompt="zcodex> " \
            --with-nth=2.. \
            --delimiter=$'\t') || exit 0

      [ -n "$selection" ] || exit 0

      id=$(printf '%s' "$selection" | cut -f1)
      exec zcodex resume "$id"
    '';
  };
in
{
  options.modules.home.scripts.codex-fr = {
    enable = lib.mkEnableOption "oxfr/zxfr - resume Codex sessions via ocodex/zcodex";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      ocodexFr
      zcodexFr
    ];
  };
}
