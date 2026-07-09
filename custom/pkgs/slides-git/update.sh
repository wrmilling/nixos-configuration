#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="$dir/default.nix"
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

current_version=$(sed -n 's/.*version = "\(.*\)";/\1/p' "$file")
old_rev=$(sed -n 's/.*rev = "\([^"]*\)";/\1/p' "$file")

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

sed -i.bak \
  -e "s#version = \"${current_version}\";#version = \"${new_version}\";#" \
  -e "s#rev = \"${old_rev}\";#rev = \"${new_rev}\";#" \
  "$file"
rm -f "$file.bak"

# 1. src hash (fetchFromGitHub's `sha256`, distinct from the `vendorHash` key
# further down).
old_src_hash=$(sed -n 's/.*[^a-zA-Z]sha256 = "\(sha256-[^"]*\)";/\1/p' "$file" | head -1)
sed -i.bak "s#${old_src_hash}#${fakehash}#" "$file"
rm -f "$file.bak"
new_src_hash=$(resolve_hash)
sed -i.bak "s#${fakehash}#${new_src_hash}#" "$file"
rm -f "$file.bak"
echo "src sha256 -> $new_src_hash"

# 2. vendorHash (depends on the new src's go.mod/go.sum, so it must be
# re-resolved after the src hash above is already correct).
old_vendor_hash=$(sed -n 's/.*vendorHash = "\(sha256-[^"]*\)";/\1/p' "$file")
sed -i.bak "s#${old_vendor_hash}#${fakehash}#" "$file"
rm -f "$file.bak"
new_vendor_hash=$(resolve_hash)
sed -i.bak "s#${fakehash}#${new_vendor_hash}#" "$file"
rm -f "$file.bak"
echo "vendorHash -> $new_vendor_hash"

echo "Updated slides $current_version -> $new_version"
