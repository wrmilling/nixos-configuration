#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="$dir/default.nix"
flake_root="$(cd "$dir/../../.." && pwd)"
fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

current_version=$(sed -n 's/.*version = "\(.*\)".*/\1/p' "$file")
new_version=$(gh api repos/kincoy/cc9s/releases/latest --jq .tag_name | sed 's/^v//')

if [[ "$new_version" == "$current_version" ]]; then
  echo "cc9s already up to date at $current_version"
  exit 0
fi

old_sha256=$(sed -n 's/.*sha256 = "\(.*\)".*/\1/p' "$file" | head -n1)
old_vendor_hash=$(sed -n 's/.*vendorHash = "\(.*\)".*/\1/p' "$file")

sed -i.bak "s#version = \"${current_version}\"#version = \"${new_version}\"#" "$file"
sed -i.bak "s#sha256 = \"${old_sha256}\"#sha256 = \"${fake_hash}\"#" "$file"
sed -i.bak "s#vendorHash = \"${old_vendor_hash}\"#vendorHash = \"${fake_hash}\"#" "$file"
rm -f "$file.bak"

build_and_get_hash() {
  nix build "$flake_root#cc9s" 2>&1 | sed -n 's/.*got:\s*//p' | head -n1
}

new_sha256=$(build_and_get_hash)
if [[ -z "$new_sha256" ]]; then
  echo "Failed to determine src sha256 - see build output above" >&2
  exit 1
fi
sed -i.bak "s#sha256 = \"${fake_hash}\"#sha256 = \"${new_sha256}\"#" "$file"
rm -f "$file.bak"

new_vendor_hash=$(build_and_get_hash)
if [[ -z "$new_vendor_hash" ]]; then
  echo "Failed to determine vendorHash - see build output above" >&2
  exit 1
fi
sed -i.bak "s#vendorHash = \"${fake_hash}\"#vendorHash = \"${new_vendor_hash}\"#" "$file"
rm -f "$file.bak"

echo "  sha256:     $old_sha256 -> $new_sha256"
echo "  vendorHash: $old_vendor_hash -> $new_vendor_hash"
echo "Updated cc9s $current_version -> $new_version"
