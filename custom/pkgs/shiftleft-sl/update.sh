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

case "$(uname -s)" in
  Linux) host_os=linux ;;
  Darwin) host_os=osx ;;
  *)
    echo "Unsupported host OS: $(uname -s)" >&2
    exit 1
    ;;
esac
case "$(uname -m)" in
  x86_64) host_arch=x64 ;;
  arm64 | aarch64) host_arch=arm64 ;;
  *)
    echo "Unsupported host arch: $(uname -m)" >&2
    exit 1
    ;;
esac

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# ShiftLeft has no version-listing API, so the current version is discovered
# by downloading the "latest" alias for the host platform and asking the
# binary itself.
curl -sfL -o "$tmpdir/sl.tar.gz" "https://cdn.shiftleft.io/download/sl-latest-${host_os}-${host_arch}.tar.gz"
tar -xzf "$tmpdir/sl.tar.gz" -C "$tmpdir"
chmod +x "$tmpdir/sl"
new_version=$("$tmpdir/sl" --version | awk '{print $3}')

if [[ "$new_version" == "$current_version" ]]; then
  echo "shiftleft-sl already up to date at $current_version"
  exit 0
fi

platforms='
x86_64-linux linux x64
aarch64-linux linux arm64
x86_64-darwin osx x64
aarch64-darwin osx arm64
'

while read -r plat os arch; do
  [ -z "$plat" ] && continue
  old_hash=$(get_hash "$plat")
  url="https://cdn.shiftleft.io/download/sl-${new_version}-${os}-${arch}.tar.gz"
  new_hash=$(nix --extra-experimental-features nix-command store prefetch-file --hash-type sha256 --json "$url" | jq -r .hash)
  sed -i.bak "s#${old_hash}#${new_hash}#" "$file"
  rm -f "$file.bak"
  echo "$plat: $old_hash -> $new_hash"
done <<<"$platforms"

sed -i.bak "s#version = \"${current_version}\"#version = \"${new_version}\"#" "$file"
rm -f "$file.bak"

echo "Updated shiftleft-sl $current_version -> $new_version"
