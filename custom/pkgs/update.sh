#!/usr/bin/env bash
# Update one (or every) package in custom/pkgs, regardless of which update
# mechanism it uses under the hood:
#   - most packages have a plain custom/pkgs/<name>/update.sh -- run directly
#   - codegraph exposes its update script as a real derivation
#     (passthru.updateScript, ported from the upstream nixpkgs package)
#     instead, which has to be built before it can run
#
# Usage:
#   custom/pkgs/update.sh            # update every package
#   custom/pkgs/update.sh <name>      # update one package, e.g. codegraph
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
system=$(nix eval --raw --impure --expr 'builtins.currentSystem')

update_one() {
  local name="$1"
  echo "=== $name ==="
  if [[ -x "$dir/$name/update.sh" ]]; then
    "$dir/$name/update.sh"
  else
    local script
    script=$(cd "$dir" && nix build --no-link --print-out-paths ".#packages.$system.$name.passthru.updateScript")
    (cd "$dir" && "$script")
  fi
}

if [[ $# -eq 0 ]]; then
  for pkg_dir in "$dir"/*/; do
    update_one "$(basename "$pkg_dir")"
  done
else
  update_one "$1"
fi
