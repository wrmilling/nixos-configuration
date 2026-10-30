#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versions_file="$dir/versions.json"

current_version=$(nix shell nixpkgs#jq -c jq -r '.version' "$versions_file")
# Releases are published to releases.herdr.dev, not as GitHub Releases.
new_version=$(curl -fsSL https://releases.herdr.dev/core/latest.json | nix shell nixpkgs#jq -c jq -r '.version')

if [[ "$new_version" == "$current_version" ]]; then
  echo "herdr-core already up to date at $current_version"
  exit 0
fi

platforms='
x86_64-linux linux-x86_64
aarch64-linux linux-aarch64
x86_64-darwin macos-x86_64
aarch64-darwin macos-aarch64
'

hashes_json="{}"
while read -r plat target; do
  [ -z "$plat" ] && continue
  url="https://releases.herdr.dev/core/${new_version}/herdr-core-${target}.tar.gz"
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
echo "Updated herdr-core $current_version -> $new_version"
