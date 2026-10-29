#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$dir/../../.." && pwd)"
versions_file="$dir/versions.json"

jq() { nix shell nixpkgs#jq -c jq "$@"; }

current_version=$(jq -r '.version' "$versions_file")
new_version=$(gh api repos/morluto/rea/releases/latest --jq .tag_name | sed 's/^rea-agents-//')

if [[ "$new_version" == "$current_version" ]]; then
  echo "rea already up to date at $current_version"
  exit 0
fi

prefetch_file() {
  nix --extra-experimental-features nix-command store prefetch-file --hash-type sha256 --json "$@"
}
prefetch_github() {
  prefetch_file --unpack "https://github.com/$1/$2/archive/$3.tar.gz" | jq -r '.hash'
}

src_json=$(prefetch_file "https://registry.npmjs.org/rea-agents/-/rea-agents-${new_version}.tgz")
src_hash=$(printf '%s' "$src_json" | jq -r '.hash')
src_path=$(printf '%s' "$src_json" | jq -r '.storePath')
lockfile_json=$(prefetch_file "https://raw.githubusercontent.com/morluto/rea/rea-agents-${new_version}/package-lock.json")
lockfile_hash=$(printf '%s' "$lockfile_json" | jq -r '.hash')
lockfile_path=$(printf '%s' "$lockfile_json" | jq -r '.storePath')

frida_version=$(jq -r '.packages["node_modules/frida"].version' "$lockfile_path")
frida_hashes='{}'
for pair in x86_64-linux:linux-x64 aarch64-linux:linux-arm64 x86_64-darwin:darwin-x64 aarch64-darwin:darwin-arm64; do
  system=${pair%%:*}
  plat=${pair#*:}
  hash=$(prefetch_file "https://github.com/frida/frida/releases/download/${frida_version}/frida-v${frida_version}-napi-v8-${plat}.tar.gz" | jq -r '.hash')
  frida_hashes=$(printf '%s' "$frida_hashes" | jq --arg system "$system" --arg hash "$hash" '.[$system] = $hash')
done

# The external engine versions rea audits are pinned in its compiled sources.
jadx_release=$(tar -xzOf "$src_path" package/dist/android/JadxRelease.js)
jadx_version=$(printf '%s' "$jadx_release" | sed -n 's/^ *version: "\(.*\)",$/\1/p' | head -1)
jadx_hash=$(nix --extra-experimental-features nix-command hash to-sri --type sha256 "$(printf '%s' "$jadx_release" | sed -n 's/^ *sha256: "\(.*\)",$/\1/p')")

pwntools_profile=$(tar -xzOf "$src_path" package/dist/native/pwntools/PwntoolsRelease.js | sed -n 's/^ *version: "\(pwntools@.*\)",$/\1/p')
profile_version() { printf '%s' "$pwntools_profile" | tr ';' '\n' | sed -n "s/^$1@//p"; }
pwntools_version=$(profile_version pwntools)
pyelftools_version=$(profile_version pyelftools)
unicorn_version=$(profile_version unicorn)
pyelftools_hash=$(prefetch_github eliben pyelftools "v${pyelftools_version}")
unicorn_hash=$(prefetch_github unicorn-engine unicorn "${unicorn_version}")

nixpkgs_pwntools=$(nix eval --raw "$repo_root#rea.pwntoolsPython.pkgs.pwntools.version")
if [[ "$nixpkgs_pwntools" != "$pwntools_version" ]]; then
  echo "warning: rea $new_version audits pwntools $pwntools_version but nixpkgs has $nixpkgs_pwntools" >&2
fi

write_versions() {
  jq \
    --arg version "$new_version" \
    --arg src "$src_hash" \
    --arg lockfile "$lockfile_hash" \
    --arg npmDepsHash "$1" \
    --arg jadxVersion "$jadx_version" \
    --arg jadxHash "$jadx_hash" \
    --arg pyelftoolsVersion "$pyelftools_version" \
    --arg pyelftoolsHash "$pyelftools_hash" \
    --arg unicornVersion "$unicorn_version" \
    --arg unicornHash "$unicorn_hash" \
    --arg fridaVersion "$frida_version" \
    --argjson fridaHashes "$frida_hashes" \
    '.version = $version
    | .hashes = { src: $src, lockfile: $lockfile }
    | .npmDepsHash = $npmDepsHash
    | .jadxMcp = { version: $jadxVersion, hash: $jadxHash }
    | .pwntools = {
        pyelftools: { version: $pyelftoolsVersion, hash: $pyelftoolsHash },
        unicorn: { version: $unicornVersion, hash: $unicornHash }
      }
    | .frida = { version: $fridaVersion, hashes: $fridaHashes }' \
    "$versions_file" > "$versions_file.tmp"
  mv "$versions_file.tmp" "$versions_file"
}

write_versions "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
npm_deps_hash=$(nix build --impure --no-link "$repo_root#rea.npmDeps" 2>&1 | sed -n 's/^ *got: *//p' || true)
if [[ -z "$npm_deps_hash" ]]; then
  echo "failed to resolve npmDepsHash" >&2
  exit 1
fi
write_versions "$npm_deps_hash"

echo "Written to ${versions_file}"
echo "Updated rea $current_version -> $new_version"
