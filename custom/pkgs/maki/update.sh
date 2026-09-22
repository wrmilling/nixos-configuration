#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versions_file="$dir/versions.json"

current_version=$(nix shell nixpkgs#jq -c jq -r '.version' "$versions_file")
new_version=$(gh api repos/tontinton/maki/releases/latest --jq .tag_name | sed 's/^v//')

if [[ "$new_version" == "$current_version" ]]; then
  echo "maki already up to date at $current_version"
  exit 0
fi

platforms='
x86_64-linux x86_64-unknown-linux-musl
aarch64-linux aarch64-unknown-linux-musl
x86_64-darwin x86_64-apple-darwin
aarch64-darwin aarch64-apple-darwin
'

hashes_json="{}"
while read -r plat asset; do
  [ -z "$plat" ] && continue
  url="https://github.com/tontinton/maki/releases/download/v${new_version}/maki-v${new_version}-${asset}.tar.gz"
  new_hash=$(nix --extra-experimental-features nix-command store prefetch-file --hash-type sha256 --json "$url" | nix shell nixpkgs#jq -c jq -r '.hash')
  hashes_json=$(printf '%s' "$hashes_json" | nix shell nixpkgs#jq -c jq --arg plat "$plat" --arg hash "$new_hash" '.[$plat] = $hash')
  echo "$plat: $new_hash"
done <<<"$platforms"

nix shell nixpkgs#jq -c jq \
  --arg version "$new_version" \
  --argjson hashes "$hashes_json" \
  '.version = $version | .hashes = $hashes' \
  "$versions_file" > "$versions_file.tmp"
mv "$versions_file.tmp" "$versions_file"

echo "Written to ${versions_file}"
echo "Updated maki $current_version -> $new_version"
