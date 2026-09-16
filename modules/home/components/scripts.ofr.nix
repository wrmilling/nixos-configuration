{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.scripts.ofr;
  ofr = pkgs.writeShellApplication {
    name = "ofr";
    runtimeInputs = [
      pkgs.fast-resume
      pkgs.jq
      pkgs.fzf
      pkgs.coreutils
    ];
    text = ''
      if ! command -v oclaude >/dev/null 2>&1; then
        echo "ofr: oclaude not found on PATH. Enable modules.home.terminal.claude-code.oclaude.apiKeyFile." >&2
        exit 1
      fi

      if { [ "$#" -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; }; then
        cat <<'EOF'
      usage: ofr [fr-args...]

      Pick a Claude Code session and resume it via oclaude (OpenCode Go endpoint).

      Forwards arguments to `fr --json`, lets you pick a session through fzf,
      then execs `oclaude --resume <id>` for the chosen session. Defaults to
      `-a claude` when no agent filter is given.

      Examples:
        ofr                       # pick from recent Claude sessions
        ofr "auth bug"            # search and pick
        ofr -d /work/backend      # filter by directory
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
        echo "ofr: fr failed" >&2
        exit 1
      fi

      count=$(printf '%s' "$json" | jq -r '.sessions | length // 0')
      if [ "$count" = "0" ]; then
        echo "ofr: no matching sessions" >&2
        exit 1
      fi

      selection=$(printf '%s' "$json" |
        jq -r '.sessions[] | [.id, .timestamp, .directory, .title] | @tsv' |
        fzf --prompt="oclaude> " \
            --with-nth=2.. \
            --delimiter=$'\t') || exit 0

      [ -n "$selection" ] || exit 0

      id=$(printf '%s' "$selection" | cut -f1)
      exec oclaude --resume "$id"
    '';
  };
in
{
  options.modules.home.scripts.ofr = {
    enable = lib.mkEnableOption "ofr - resume Claude Code sessions via oclaude";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ ofr ];
  };
}
