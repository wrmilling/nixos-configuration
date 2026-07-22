#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versions_file="$dir/versions.json"

current_version=$(nix shell nixpkgs#jq -c jq -r '.version' "$versions_file")
new_version=$(curl --silent -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/OliverBalfour/obsidian-pandoc/releases/latest" | sed -n 's#.*/releases/tag/##p')

if [[ "$new_version" == "$current_version" ]]; then
  echo "obsidian-pandoc already up to date at $current_version"
  exit 0
fi

assets='
manifest manifest.json
main main.js
styles styles.css
'

hashes_json="{}"
while read -r key asset; do
  [ -z "$key" ] && continue
  url="https://github.com/OliverBalfour/obsidian-pandoc/releases/download/${new_version}/${asset}"
  new_hash=$(nix --extra-experimental-features nix-command store prefetch-file --hash-type sha256 --json "$url" | nix shell nixpkgs#jq -c jq -r '.hash')
  hashes_json=$(printf '%s' "$hashes_json" | nix shell nixpkgs#jq -c jq --arg key "$key" --arg hash "$new_hash" '.[$key] = $hash')
  echo "$key: $new_hash"
done <<<"$assets"

nix shell nixpkgs#jq -c jq \
  --arg version "$new_version" \
  --argjson hashes "$hashes_json" \
  '.version = $version | .hashes = $hashes' \
  "$versions_file" > "$versions_file.tmp"
mv "$versions_file.tmp" "$versions_file"

echo "Written to ${versions_file}"
echo "Updated obsidian-pandoc $current_version -> $new_version"
