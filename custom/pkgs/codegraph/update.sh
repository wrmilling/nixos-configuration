#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="$dir/default.nix"

get_hash() {
  awk -v plat="\"$1\" = fetchurl {" '
    index($0, plat) > 0 { found = 1 }
    found && index($0, "hash") > 0 {
      line = $0
      sub(/.*hash = "/, "", line)
      sub(/".*/, "", line)
      print line
      exit
    }
  ' "$file"
}

current_version=$(sed -n 's/.*version = "\(.*\)";/\1/p' "$file")
new_version=$(curl --silent -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/colbymchenry/codegraph/releases/latest" | sed -n 's#.*/releases/tag/v##p')

if [[ "$new_version" == "$current_version" ]]; then
  echo "codegraph already up to date at $current_version"
  exit 0
fi

platforms='
aarch64-darwin codegraph-darwin-arm64
aarch64-linux codegraph-linux-arm64
x86_64-darwin codegraph-darwin-x64
x86_64-linux codegraph-linux-x64
'

while read -r plat asset; do
  [ -z "$plat" ] && continue
  old_hash=$(get_hash "$plat")
  url="https://github.com/colbymchenry/codegraph/releases/download/v${new_version}/${asset}.tar.gz"
  new_hash=$(nix --extra-experimental-features nix-command store prefetch-file --hash-type sha256 "$url" 2>&1 | grep -oE "sha256-[A-Za-z0-9+/=]+")
  sed -i.bak "s#${old_hash}#${new_hash}#" "$file"
  rm -f "$file.bak"
  echo "$plat: $old_hash -> $new_hash"
done <<<"$platforms"

sed -i.bak "s#version = \"${current_version}\"#version = \"${new_version}\"#" "$file"
rm -f "$file.bak"

echo "Updated codegraph $current_version -> $new_version"
