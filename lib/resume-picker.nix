# Builds an `fr`-backed picker over several harnesses that resumes the chosen
# session through that harness's provider launcher (zclaude, zcodex, ...),
# reusing fr's own resume_command with the launcher swapped in.
{ pkgs, lib }:
{
  name,
  launchers,
  description,
  enableHint,
}:
pkgs.writeShellApplication {
  inherit name;
  runtimeInputs = [
    pkgs.fast-resume
    pkgs.jq
    pkgs.fzf
    pkgs.coreutils
  ];
  text = ''
    declare -A launchers=(${
      lib.concatStringsSep " " (lib.mapAttrsToList (agent: launcher: "[${agent}]=${launcher}") launchers)
    })

    if { [ "$#" -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; }; then
      cat <<'EOF'
    usage: ${name} [fr-args...]

    ${description}

    Forwards arguments to `fr --json`, lists sessions from every harness
    whose launcher is on PATH (${
      lib.concatStringsSep ", " (
        lib.mapAttrsToList (agent: launcher: "${agent} via ${launcher}") launchers
      )
    }), lets you pick one through fzf, then resumes it with fr's resume
    command run through the matching launcher.

    Examples:
      ${name}                       # pick from recent sessions
      ${name} "auth bug"            # search and pick
      ${name} -a codex              # only Codex sessions
      ${name} -d /work/backend      # filter by directory
    EOF
      exit 0
    fi

    agents=()
    for agent in "''${!launchers[@]}"; do
      if command -v "''${launchers[$agent]}" >/dev/null 2>&1; then
        agents+=("$agent")
      fi
    done
    if [ "''${#agents[@]}" -eq 0 ]; then
      echo "${name}: none of ${lib.concatStringsSep ", " (lib.attrValues launchers)} found on PATH. Set ${enableHint}." >&2
      exit 1
    fi

    if ! json=$(fr --json --all "$@"); then
      echo "${name}: fr failed" >&2
      exit 1
    fi

    json=$(printf '%s' "$json" | jq --args '.sessions |= map(select(.agent as $a | $ARGS.positional | index($a)))' "''${agents[@]}")

    count=$(printf '%s' "$json" | jq -r '.sessions | length')
    if [ "$count" = "0" ]; then
      echo "${name}: no matching sessions" >&2
      exit 1
    fi

    selection=$(printf '%s' "$json" |
      jq -r '.sessions[] | [.id, .agent, .timestamp, .directory, .title] | @tsv' |
      fzf --prompt=${lib.escapeShellArg "${name}> "} \
          --with-nth=2.. \
          --delimiter=$'\t') || exit 0

    [ -n "$selection" ] || exit 0

    id=$(printf '%s' "$selection" | cut -f1)
    agent=$(printf '%s' "$selection" | cut -f2)
    mapfile -t cmd < <(printf '%s' "$json" | jq -r --arg id "$id" '.sessions[] | select(.id == $id) | .resume_command[]')
    cmd[0]="''${launchers[$agent]}"
    exec "''${cmd[@]}"
  '';
}
