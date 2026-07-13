#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versions_file="$dir/versions.json"

current_version=$(nix shell nixpkgs#jq -c jq -r '.version' "$versions_file")
new_version=$(gh api repos/controlplaneio-fluxcd/flux-operator/releases/latest --jq .tag_name | sed 's/^v//')

if [[ "$new_version" == "$current_version" ]]; then
  echo "flux-operator-mcp already up to date at $current_version"
  exit 0
fi

platforms='
x86_64-linux linux amd64
aarch64-linux linux arm64
x86_64-darwin darwin amd64
aarch64-darwin darwin arm64
'

hashes_json="{}"
while read -r plat os arch; do
  [ -z "$plat" ] && continue
  url="https://github.com/controlplaneio-fluxcd/flux-operator/releases/download/v${new_version}/flux-operator-mcp_${new_version}_${os}_${arch}.tar.gz"
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
echo "Updated flux-operator-mcp $current_version -> $new_version"
