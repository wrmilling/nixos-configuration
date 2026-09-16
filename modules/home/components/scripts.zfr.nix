{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.scripts.zfr;
  zfr = pkgs.writeShellApplication {
    name = "zfr";
    runtimeInputs = [
      pkgs.fast-resume
      pkgs.jq
      pkgs.fzf
      pkgs.coreutils
    ];
    text = ''
      if ! command -v zclaude >/dev/null 2>&1; then
        echo "zfr: zclaude not found on PATH. Enable modules.home.terminal.claude-code.zclaude.apiKeyFile." >&2
        exit 1
      fi

      if { [ "$#" -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; }; then
        cat <<'EOF'
      usage: zfr [fr-args...]

      Pick a Claude Code session and resume it via zclaude (z.ai endpoint).

      Forwards arguments to `fr --json`, lets you pick a session through fzf,
      then execs `zclaude --resume <id>` for the chosen session. Defaults to
      `-a claude` when no agent filter is given.

      Examples:
        zfr                       # pick from recent Claude sessions
        zfr "auth bug"            # search and pick
        zfr -d /work/backend      # filter by directory
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
        set -- -a claude "$@"
      fi

      if ! json=$(fr --json --all "$@"); then
        echo "zfr: fr failed" >&2
        exit 1
      fi

      count=$(printf '%s' "$json" | jq -r '.sessions | length // 0')
      if [ "$count" = "0" ]; then
        echo "zfr: no matching sessions" >&2
        exit 1
      fi

      selection=$(printf '%s' "$json" |
        jq -r '.sessions[] | [.id, .timestamp, .directory, .title] | @tsv' |
        fzf --prompt="zclaude> " \
            --with-nth=2.. \
            --delimiter=$'\t') || exit 0

      [ -n "$selection" ] || exit 0

      id=$(printf '%s' "$selection" | cut -f1)
      exec zclaude --resume "$id"
    '';
  };
in
{
  options.modules.home.scripts.zfr = {
    enable = lib.mkEnableOption "zfr - resume Claude Code sessions via zclaude";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ zfr ];
  };
}
