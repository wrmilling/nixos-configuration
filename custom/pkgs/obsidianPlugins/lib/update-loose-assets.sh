#!/usr/bin/env bash
# Shared update logic for Obsidian community plugins packaged from loose
# GitHub release assets (manifest.json/main.js/[styles.css]). Sourced by
# each plugin's own update.sh, which sets $dir and then calls
# update_obsidian_plugin. See ../tasknotes/update.sh for the minimal wrapper.
set -euo pipefail

# update_obsidian_plugin <owner/repo> <pname> [key:filename ...]
# Default assets: manifest:manifest.json main:main.js styles:styles.css
update_obsidian_plugin() {
  local repo="$1" pname="$2"
  shift 2
  local assets=("$@")
  if [ "${#assets[@]}" -eq 0 ]; then
    assets=(manifest:manifest.json main:main.js styles:styles.css)
  fi

  local versions_file="$dir/versions.json"
  local current_version new_version
  current_version=$(nix shell nixpkgs#jq -c jq -r '.version' "$versions_file")
  new_version=$(gh api "repos/$repo/releases/latest" --jq .tag_name)

  if [[ "$new_version" == "$current_version" ]]; then
    echo "$pname already up to date at $current_version"
    exit 0
  fi

  local hashes_json="{}"
  local entry key asset new_hash url
  for entry in "${assets[@]}"; do
    key="${entry%%:*}"
    asset="${entry#*:}"
    url="https://github.com/$repo/releases/download/${new_version}/${asset}"
    new_hash=$(nix --extra-experimental-features nix-command store prefetch-file --hash-type sha256 --json "$url" | nix shell nixpkgs#jq -c jq -r '.hash')
    hashes_json=$(printf '%s' "$hashes_json" | nix shell nixpkgs#jq -c jq --arg key "$key" --arg hash "$new_hash" '.[$key] = $hash')
    echo "$key: $new_hash"
  done

  nix shell nixpkgs#jq -c jq \
    --arg version "$new_version" \
    --argjson hashes "$hashes_json" \
    '.version = $version | .hashes = $hashes' \
    "$versions_file" > "$versions_file.tmp"
  mv "$versions_file.tmp" "$versions_file"

  echo "Written to ${versions_file}"
  echo "Updated $pname $current_version -> $new_version"
}
