#!/usr/bin/env bash
# Update one (or every) package in custom/pkgs, regardless of which update
# mechanism it uses under the hood:
#   - most packages have a plain custom/pkgs/<name>/update.sh -- run directly
#   - codegraph exposes its update script as a real derivation
#     (passthru.updateScript, ported from the upstream nixpkgs package)
#     instead, which has to be built before it can run
#   - some packages are grouped under a namespace directory instead of being
#     flat (e.g. obsidianPlugins/<name>) -- descend into those
#
# Usage:
#   custom/pkgs/update.sh                     # update every package
#   custom/pkgs/update.sh <name>               # update one package, e.g. codegraph
#   custom/pkgs/update.sh <namespace>/<name>   # update one namespaced package, e.g. obsidianPlugins/dataview
set -euo pipefail

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

list_all() {
  local pkg_dir name sub_dir
  for pkg_dir in "$dir"/*/; do
    name="$(basename "$pkg_dir")"
    if [[ -f "$pkg_dir/versions.json" ]]; then
      echo "$name"
    else
      for sub_dir in "$pkg_dir"*/; do
        [[ -f "$sub_dir/versions.json" ]] || continue
        echo "$name/$(basename "$sub_dir")"
      done
    fi
  done
}

if [[ $# -eq 0 ]]; then
  while IFS= read -r name; do
    update_one "$name"
  done < <(list_all)
else
  update_one "$1"
fi
