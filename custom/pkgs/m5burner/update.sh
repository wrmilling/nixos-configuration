#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versions_file="$dir/versions.json"
repo_root="$(cd "$dir/../../.." && pwd)"

fakehash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# fetchzip needs the hash of the *unpacked* tree, not a flat file hash, so
# `nix store prefetch-file` (used elsewhere in custom/pkgs) doesn't apply
# directly. Instead: point the hash at a placeholder, rebuild, and read the
# real hash out of nix's mismatch error.
resolve_hash() {
  local out
  # m5burner's license is unfreeRedistributable, which the bare `packages.<system>`
  # flake output evaluates without the `nixpkgs.config.allowUnfree = true;` that
  # the real home-manager/nixos configs set -- so allow it just for this check.
  out=$(cd "$repo_root" && NIXPKGS_ALLOW_UNFREE=1 nix --extra-experimental-features "nix-command flakes" build --no-link --impure ".#m5burner" 2>&1) && {
    echo "expected a hash mismatch (placeholder hash) but the build succeeded" >&2
    return 1
  }
  local hash
  hash=$(printf '%s\n' "$out" | sed -n 's/^ *got: *//p' | tail -1)
  if [[ -z "$hash" ]]; then
    echo "could not determine hash from build output:" >&2
    printf '%s\n' "$out" >&2
    return 1
  fi
  printf '%s' "$hash"
}

# M5Burner has no versioned download URL or public update feed -- the CDN
# link always points at whatever the current beta build is, with no way to
# check "is there something newer" ahead of time. So this just re-fetches
# and compares hashes; a changed hash means M5Stack shipped a new build under
# the same URL. `version` (currently the fixed label "3.0-beta") should be
# bumped by hand afterwards if you can find a real version number for the
# new build (e.g. the app's About screen) -- the CDN doesn't expose one.
old_hash=$(nix shell nixpkgs#jq -c jq -r '.hash' "$versions_file")

nix shell nixpkgs#jq -c jq --arg h "$fakehash" '.hash = $h' "$versions_file" > "$versions_file.tmp"
mv "$versions_file.tmp" "$versions_file"

new_hash=$(resolve_hash)

nix shell nixpkgs#jq -c jq --arg h "$new_hash" '.hash = $h' "$versions_file" > "$versions_file.tmp"
mv "$versions_file.tmp" "$versions_file"

if [[ "$new_hash" == "$old_hash" ]]; then
  echo "m5burner already up to date (hash unchanged)"
else
  echo "Updated m5burner (hash changed: $old_hash -> $new_hash; version unchanged -- bump manually in versions.json if a real version can be found)"
fi
