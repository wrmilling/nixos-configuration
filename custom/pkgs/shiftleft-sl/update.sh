#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
versions_file="$dir/versions.json"

current_version=$(nix shell nixpkgs#jq -c jq -r '.version' "$versions_file")

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

hashes_json="{}"
while read -r plat os arch; do
  [ -z "$plat" ] && continue
  url="https://cdn.shiftleft.io/download/sl-${new_version}-${os}-${arch}.tar.gz"
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
echo "Updated shiftleft-sl $current_version -> $new_version"
