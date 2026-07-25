#!/usr/bin/env bash
set -euo pipefail

print_help() {
  cat <<'EOF'
usage: update.sh [<name>|<namespace>/<name>|--list|--matrix|-h|--help]

Update one (or every) package in custom/pkgs; see custom/README.md and the
custom-packaging skill for details.

  (no args)            update every package
  <name>               update one package, e.g. codegraph
  <namespace>/<name>   update one namespaced package, e.g. obsidianPlugins/dataview
  --list               print discovered package names, one per line; update nothing
  --matrix             print [{package, system}, ...] JSON for the CI update
                       matrix, where "system" is the Forgejo runner label a
                       package's meta.platforms/badPlatforms lets it build on;
                       update nothing
EOF
}

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
system=$(nix eval --raw --impure --expr 'builtins.currentSystem')

update_one() {
  local rel="$1"
  echo "=== $rel ==="
  if [[ -x "$dir/$rel/update.sh" ]]; then
    "$dir/$rel/update.sh"
  else
    local attr="${rel//\//.}"
    local script
    script=$(cd "$dir" && nix build --no-link --print-out-paths ".#packages.$system.$attr.passthru.updateScript")
    (cd "$dir" && "$script")
  fi
}

# Packages whose update.sh just delegates to a sibling's (e.g. mcpelauncher-ui-qt-git) don't need their own entry.
is_delegate() {
  local pkg_dir="$1"
  [[ -x "$pkg_dir/update.sh" ]] && grep -qE '^exec ".*/update\.sh"' "$pkg_dir/update.sh"
}

list_all() {
  local pkg_dir name sub_dir
  for pkg_dir in "$dir"/*/; do
    name="$(basename "$pkg_dir")"
    if [[ -f "$pkg_dir/versions.json" ]]; then
      is_delegate "$pkg_dir" || echo "$name"
    else
      for sub_dir in "$pkg_dir"*/; do
        [[ -f "$sub_dir/versions.json" ]] || continue
        is_delegate "$sub_dir" || echo "$name/$(basename "$sub_dir")"
      done
    fi
  done
}

# Forgejo architectures with a registered runner (modules/nixos/components/forgejo-runner.nix).
# Both eligible -> the shared "alpine-tokyo" label (any of the 3 runners); exactly
# one eligible -> that arch's own label, restricting the job to runners that can build it.
target_system() {
  local rel="$1"
  local attr="${rel//\//.}"
  local meta_expr='p: { platforms = p.meta.platforms or null; badPlatforms = p.meta.badPlatforms or [ ]; }'
  local meta
  # Directory name and flake attribute can diverge for "-git" sourced packages
  # (e.g. mcpelauncher-client dir vs. mcpelauncher-client-git attr) -- try both.
  meta=$(nix eval --json ".#packages.$system.$attr" --apply "$meta_expr" 2>/dev/null) \
    || meta=$(nix eval --json ".#packages.$system.$attr-git" --apply "$meta_expr" 2>/dev/null) \
    || meta='{"platforms":null,"badPlatforms":[]}'
  nix shell nixpkgs#jq -c jq -rn --argjson meta "$meta" '
    ["x86_64-linux", "aarch64-linux"] as $candidates
    | ($meta.badPlatforms // []) as $bad
    | [
        $candidates[] as $c
        | select(
            (($meta.platforms == null) or (($meta.platforms | index($c)) != null))
            and (($bad | index($c)) == null)
          )
        | $c
      ] as $eligible
    | if ($eligible | length) == 2 then "alpine-tokyo"
      elif ($eligible | length) == 1 then $eligible[0]
      else empty
      end
  '
}

print_matrix() {
  local name sys
  while IFS= read -r name; do
    sys=$(target_system "$name")
    if [[ -z "$sys" ]]; then
      echo "warning: $name has no eligible Forgejo runner architecture; skipping" >&2
      continue
    fi
    nix shell nixpkgs#jq -c jq -cn --arg p "$name" --arg s "$sys" '{package: $p, system: $s}'
  done < <(list_all) | nix shell nixpkgs#jq -c jq -cs .
}

case "${1:-}" in
  -h | --help)
    print_help
    ;;
  --list)
    list_all
    ;;
  --matrix)
    print_matrix
    ;;
  "")
    while IFS= read -r name; do
      update_one "$name"
    done < <(list_all)
    ;;
  *)
    update_one "$1"
    ;;
esac
