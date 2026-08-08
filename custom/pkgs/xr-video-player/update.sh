#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versions_file="$dir/versions.json"
repo_root="$(cd "$dir/../../.." && pwd)"

fakehash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# stdenv.mkDerivation's src is a fixed-output derivation with no simple
# single-file prefetch equivalent. Instead: point the hash at a placeholder,
# rebuild, and read the real hash out of nix's mismatch error.
resolve_hash() {
  local out
  out=$(cd "$repo_root" && nix --extra-experimental-features "nix-command flakes" build --no-link ".#xr-video-player" 2>&1) && {
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

jq_set() {
  local field="$1" value="$2"
  local tmp
  tmp=$(mktemp)
  nix shell nixpkgs#jq -c jq --arg v "$value" ".${field} = \$v" "$versions_file" > "$tmp"
  mv "$tmp" "$versions_file"
}

current_version=$(nix shell nixpkgs#jq -c jq -r '.version' "$versions_file")
old_rev=$(nix shell nixpkgs#jq -c jq -r '.rev' "$versions_file")

# yoshino/xr-video-player has no releases or tags at all, so "latest release"
# isn't a signal that exists here - this package tracks the default branch's
# HEAD commit directly, using nixpkgs' usual "<version>-unstable-<date>"
# convention for untagged git pins.
new_rev=$(curl -sf "https://codeberg.org/api/v1/repos/yoshino/xr-video-player/branches/master" | nix shell nixpkgs#jq -c jq -r '.commit.id')

if [[ "$new_rev" == "$old_rev" ]]; then
  echo "xr-video-player already up to date at $current_version ($old_rev)"
  exit 0
fi

new_date=$(curl -sf "https://codeberg.org/api/v1/repos/yoshino/xr-video-player/git/commits/${new_rev}" | nix shell nixpkgs#jq -c jq -r '.commit.author.date' | cut -dT -f1)
base_version=$(echo "$current_version" | sed -E 's/-unstable-[0-9]{4}-[0-9]{2}-[0-9]{2}$//')
new_version="${base_version}-unstable-${new_date}"

echo "xr-video-player: $current_version ($old_rev) -> $new_version ($new_rev)"

# Write the placeholder rev/version so resolve_hash's rebuild picks up the new
# pin, keeping the existing hash in place until it's re-resolved below.
jq_set version "$new_version"
jq_set rev "$new_rev"

jq_set hash "$fakehash"
new_hash=$(resolve_hash)
jq_set hash "$new_hash"
echo "hash -> $new_hash"

echo "Written to ${versions_file}"
echo "Updated xr-video-player $current_version -> $new_version"
