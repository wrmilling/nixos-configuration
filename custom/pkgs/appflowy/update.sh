#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versions_file="$dir/versions.json"
repo_root="$(cd "$dir/../../.." && pwd)"

fakehash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# fetchzip needs the hash of the *unpacked* tree, not a flat file hash, so
# `nix store prefetch-file` (used elsewhere in custom/pkgs) doesn't apply
# directly, and it turns out `nix-prefetch-url --unpack` doesn't reliably
# match fetchzip's own hash either. Instead: point the hash at a
# placeholder, rebuild, and read the real hash out of nix's mismatch error.
resolve_hash() {
  local out
  # appflowy's license includes unfreeRedistributable, which the bare
  # `packages.<system>` flake output evaluates without the
  # `nixpkgs.config.allowUnfree = true;` that the real home-manager/nixos
  # configs set -- so allow it just for this check.
  out=$(cd "$repo_root" && NIXPKGS_ALLOW_UNFREE=1 nix --extra-experimental-features "nix-command flakes" build --no-link --impure ".#appflowy" 2>&1) && {
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

current_version=$(nix shell nixpkgs#jq -c jq -r '.version' "$versions_file")
new_version=$(gh api repos/AppFlowy-IO/AppFlowy/releases --jq '
  [.[] | select(.prerelease | not)] | first | .tag_name
')

if [[ "$new_version" == "$current_version" ]]; then
  echo "appflowy already up to date at $current_version"
  exit 0
fi

nix shell nixpkgs#jq -c jq --arg version "$new_version" --arg h "$fakehash" \
  '.version = $version | .hashes."x86_64-linux" = $h' \
  "$versions_file" > "$versions_file.tmp"
mv "$versions_file.tmp" "$versions_file"

new_hash=$(resolve_hash)

nix shell nixpkgs#jq -c jq --arg h "$new_hash" '.hashes."x86_64-linux" = $h' \
  "$versions_file" > "$versions_file.tmp"
mv "$versions_file.tmp" "$versions_file"

echo "Written to ${versions_file}"
echo "Updated appflowy $current_version -> $new_version"
