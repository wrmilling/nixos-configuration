#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="$dir/default.nix"

get_hash() {
  awk -v plat="\"$1\" = {" '
    index($0, plat) > 0 { found = 1 }
    found && index($0, "sha256") > 0 {
      line = $0
      sub(/.*sha256 = "/, "", line)
      sub(/".*/, "", line)
      print line
      exit
    }
  ' "$file"
}

current_version=$(sed -n 's/.*version = "\(.*\)".*/\1/p' "$file")
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

while read -r plat os arch; do
  [ -z "$plat" ] && continue
  old_hash=$(get_hash "$plat")
  url="https://github.com/controlplaneio-fluxcd/flux-operator/releases/download/v${new_version}/flux-operator-mcp_${new_version}_${os}_${arch}.tar.gz"
  new_hash=$(nix --extra-experimental-features nix-command store prefetch-file --hash-type sha256 --json "$url" | jq -r .hash)
  sed -i.bak "s#${old_hash}#${new_hash}#" "$file"
  rm -f "$file.bak"
  echo "$plat: $old_hash -> $new_hash"
done <<<"$platforms"

sed -i.bak "s#version = \"${current_version}\"#version = \"${new_version}\"#" "$file"
rm -f "$file.bak"

echo "Updated flux-operator-mcp $current_version -> $new_version"
