#!/usr/bin/env bash
# Update one (or every) package in custom/pkgs, regardless of which update
# mechanism it uses under the hood:
#   - most packages have a plain custom/pkgs/<name>/update.sh -- run directly
#   - a package ported from a nixpkgs derivation that itself exposes
#     passthru.updateScript as a real derivation (rather than a repo script)
#     falls back to building that derivation and running the result
#   - some packages are grouped under a namespace directory instead of being
#     flat (e.g. obsidianPlugins/<name>) -- descend into those
#
# Usage:
#   custom/pkgs/update.sh                     # update every package
#   custom/pkgs/update.sh <name>               # update one package, e.g. codegraph
#   custom/pkgs/update.sh <namespace>/<name>   # update one namespaced package, e.g. obsidianPlugins/dataview
#   custom/pkgs/update.sh --list               # print discovered package names, one per line, update nothing
#                                                 (this is the source of truth CI's discover job reads from --
#                                                 don't reimplement this listing logic elsewhere)
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

# A package whose update.sh is a pure `exec ".../update.sh"` delegation to a
# sibling (e.g. mcpelauncher-ui-qt-git -> mcpelauncher-client's script)
# doesn't need its own entry: the package it delegates to already covers it
# in one run, and updating both would just do redundant work (and, in CI,
# open two conflicting PRs for the same change).
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

if [[ "${1:-}" == "--list" ]]; then
  list_all
elif [[ $# -eq 0 ]]; then
  while IFS= read -r name; do
    update_one "$name"
  done < <(list_all)
else
  update_one "$1"
fi
