#!/usr/bin/env bash
set -euo pipefail

print_help() {
  cat <<'EOF'
usage: update.sh [<name>|<namespace>/<name>|--list|-h|--help]

Update one (or every) package in custom/pkgs; see custom/README.md and the
custom-packaging skill for details.

  (no args)            update every package
  <name>               update one package, e.g. codegraph
  <namespace>/<name>   update one namespaced package, e.g. obsidianPlugins/dataview
  --list               print discovered package names, one per line; update nothing
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

case "${1:-}" in
  -h | --help)
    print_help
    ;;
  --list)
    list_all
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
