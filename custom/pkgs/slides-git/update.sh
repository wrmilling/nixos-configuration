#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versions_file="$dir/versions.json"
repo_root="$(cd "$dir/../../.." && pwd)"

fakehash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# buildGoModule's src + vendorHash are both fixed-output derivations with no
# simple single-file prefetch equivalent (unlike the flat-file fetchurl
# packages elsewhere in custom/pkgs). Instead: point a hash at a placeholder,
# rebuild, and read the real hash out of nix's mismatch error -- the standard
# trick for FODs nix-update would otherwise automate.
resolve_hash() {
  local out
  out=$(cd "$repo_root" && nix --extra-experimental-features "nix-command flakes" build --no-link ".#slides-git" 2>&1) && {
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

# maaslalani/slides tags releases rarely and this package tracks its default
# branch past the last tag (the current pin is already ahead of the latest
# GitHub "release") -- so "latest release" is the wrong signal for "is there
# something newer" (an earlier version of this script used it and actually
# *downgraded* the pin). Compare against the default branch's HEAD commit
# instead, and follow nixpkgs' usual "<last-release>-unstable-<date>"
# versioning for packages pinned past their last tag.
default_branch=$(gh api repos/maaslalani/slides --jq '.default_branch')
new_rev=$(gh api "repos/maaslalani/slides/branches/${default_branch}" --jq '.commit.sha')

if [[ "$new_rev" == "$old_rev" ]]; then
  echo "slides already up to date at $current_version ($old_rev)"
  exit 0
fi

new_date=$(gh api "repos/maaslalani/slides/commits/${new_rev}" --jq '.commit.committer.date' | cut -dT -f1)
last_release=$(gh api repos/maaslalani/slides/releases/latest --jq '.tag_name' | sed 's/^v//')
new_version="${last_release}-unstable-${new_date}"

echo "slides: $current_version ($old_rev) -> $new_version ($new_rev)"

# Write the placeholder rev/version so resolve_hash's rebuild picks up the new
# pin, keeping the existing hashes in place until they're re-resolved below.
jq_set version "$new_version"
jq_set rev "$new_rev"

# 1. src hash (fetchFromGitHub's `hash`, distinct from the `vendorHash` key
# further down).
jq_set hash "$fakehash"
new_src_hash=$(resolve_hash)
jq_set hash "$new_src_hash"
echo "hash -> $new_src_hash"

# 2. vendorHash (depends on the new src's go.mod/go.sum, so it must be
# re-resolved after the src hash above is already correct).
jq_set vendorHash "$fakehash"
new_vendor_hash=$(resolve_hash)
jq_set vendorHash "$new_vendor_hash"
echo "vendorHash -> $new_vendor_hash"

echo "Written to ${versions_file}"
echo "Updated slides $current_version -> $new_version"
