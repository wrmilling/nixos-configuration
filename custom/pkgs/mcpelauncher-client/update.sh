#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versions_file="$dir/versions.json"
ui_versions_file="$dir/../mcpelauncher-ui-qt/versions.json"
repo_root="$(cd "$dir/../../.." && pwd)"

fakehash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# fetchFromGitHub here uses fetchSubmodules = true, so there's no simple
# single-file prefetch for the resulting hash (unlike the flat-file
# fetchurl packages elsewhere in custom/pkgs). Instead: point the hash at a
# placeholder, rebuild, and read the real hash out of nix's mismatch error --
# the standard trick for fixed-output derivations nix-update would otherwise
# automate.
#
# mcpelauncher-ui-qt-git depends on the sibling mcpelauncher-client-git
# package (for its `version`), which only resolves through the fully
# overlay-applied `pkgs` (the plain flake `packages.<system>` output is built
# from raw nixpkgs, without the "additions" overlay that makes packages in
# custom/pkgs visible to each other). So reconstruct that overlaid pkgs
# in-place rather than building the bare flake attribute.
resolve_hash() {
  local attr="$1" out
  out=$(cd "$repo_root" && nix --extra-experimental-features "nix-command flakes" build --no-link --impure --expr "
    let
      flake = builtins.getFlake (toString ./.);
      pkgs = import flake.inputs.nixpkgs {
        system = builtins.currentSystem;
        overlays = builtins.attrValues flake.overlays;
      };
    in pkgs.${attr}
  " 2>&1) && {
    echo "expected a hash mismatch (placeholder hash) but '$attr' built successfully" >&2
    return 1
  }
  local hash
  hash=$(printf '%s\n' "$out" | sed -n 's/^ *got: *//p' | tail -1)
  if [[ -z "$hash" ]]; then
    echo "could not determine hash for '$attr' from build output:" >&2
    printf '%s\n' "$out" >&2
    return 1
  fi
  printf '%s' "$hash"
}

jq_set() {
  local file="$1" field="$2" value="$3"
  nix shell nixpkgs#jq -c jq --arg v "$value" ".${field} = \$v" "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

current_version=$(nix shell nixpkgs#jq -c jq -r '.version' "$versions_file")

# Only the "-qt6" tags matter here -- this package builds the Qt6 UI variant;
# the plain "vX.Y.Z" tags (no suffix) are the older Qt5/CLI-only line.
new_version=$(gh api repos/minecraft-linux/mcpelauncher-manifest/tags --jq '
  [.[] | select(.name | endswith("-qt6"))][0].name' | sed 's/^v//')

if [[ "$new_version" == "$current_version" ]]; then
  echo "mcpelauncher-client already up to date at $current_version"
  exit 0
fi

echo "mcpelauncher-client: $current_version -> $new_version"

jq_set "$versions_file" version "$new_version"

jq_set "$versions_file" hash "$fakehash"
new_hash=$(resolve_hash "mcpelauncher-client-git")
jq_set "$versions_file" hash "$new_hash"
echo "mcpelauncher-client hash -> $new_hash"

# mcpelauncher-ui-qt has no version of its own -- it inherits `version` from
# this package and tracks the same "v<version>" tag on a sibling repo (see the
# NOTE above the `src` block below), so bump its hash here too.
jq_set "$ui_versions_file" hash "$fakehash"
new_ui_hash=$(resolve_hash "mcpelauncher-ui-qt-git")
jq_set "$ui_versions_file" hash "$new_ui_hash"
echo "mcpelauncher-ui-qt hash -> $new_ui_hash"

echo "Updated mcpelauncher-client + mcpelauncher-ui-qt $current_version -> $new_version"
