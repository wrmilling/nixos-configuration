#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versions_file="$dir/versions.json"

current_version=$(nix shell nixpkgs#jq -c jq -r '.version' "$versions_file")

# Not every gomuks release ships desktop .deb assets yet, so scan recent
# releases (newest first) for the first one that does, rather than assuming
# the latest tag has them.
new_tag=$(gh api repos/gomuks/gomuks/releases --jq '
  [.[] | select(any(.assets[]; .name | test("^gomuks-desktop_.*_amd64\\.deb$")))] | first | .tag_name // empty
')

if [[ -z "$new_tag" ]]; then
  echo "No gomuks release with desktop assets found" >&2
  exit 1
fi

new_version=$(gh api "repos/gomuks/gomuks/releases/tags/$new_tag" --jq '
  .assets[] | select(.name | test("^gomuks-desktop_.*_amd64\\.deb$")) | .name
' | sed -E 's/^gomuks-desktop_(.*)_amd64\.deb$/\1/')

if [[ "$new_version" == "$current_version" ]]; then
  echo "gomuks-desktop already up to date at $current_version"
  exit 0
fi

platforms='
x86_64-linux amd64
aarch64-linux arm64
'

hashes_json="{}"
while read -r plat arch; do
  [ -z "$plat" ] && continue
  url="https://github.com/gomuks/gomuks/releases/download/${new_tag}/gomuks-desktop_${new_version}_${arch}.deb"
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
echo "Updated gomuks-desktop $current_version -> $new_version"
