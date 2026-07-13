#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
package_file="$script_dir/default.nix"
versions_file="$script_dir/versions.json"
repo_root="$(cd "$script_dir/../../.." && pwd)"

current_version=$(nix shell nixpkgs#jq -c jq -r '.version' "$versions_file")
new_version=$(gh api repos/kincoy/cc9s/releases/latest --jq '.tag_name | ltrimstr("v")')

if [[ "$new_version" == "$current_version" ]]; then
  echo "cc9s already up to date at $current_version"
  exit 0
fi

echo "Updating cc9s to version: ${new_version}" >&2
tag="v${new_version}"

echo "Prefetching source hash..." >&2

src_json="$(
  nix store prefetch-file \
    --json \
    --unpack \
    "https://github.com/kincoy/cc9s/archive/refs/tags/${tag}.tar.gz"
)"

src_hash="$(
  printf '%s\n' "$src_json" |
    nix shell nixpkgs#jq -c jq -r '.hash'
)"

if [[ -z "$src_hash" || "$src_hash" == "null" ]]; then
  echo "error: failed to determine source hash" >&2
  echo "$src_json" >&2
  exit 1
fi

echo "Source hash: ${src_hash}" >&2
echo >&2

echo "Computing vendorHash. This intentionally builds with lib.fakeHash..." >&2

tmp_log="$(mktemp)"
trap 'rm -f "$tmp_log"' EXIT

set +e
nix build \
  --no-link \
  --impure \
  --expr "
    let
      flake = builtins.getFlake \"path:${repo_root}\";
      system = builtins.currentSystem;
      pkgs = import flake.inputs.nixpkgs {
        inherit system;
      };
      pkg = pkgs.callPackage ${package_file} {};
    in
      pkg.overrideAttrs (old: {
        version = \"${new_version}\";
        src = pkgs.fetchFromGitHub {
          owner = \"kincoy\";
          repo = \"cc9s\";
          rev = \"${tag}\";
          hash = \"${src_hash}\";
        };
        vendorHash = pkgs.lib.fakeHash;
      })
  " 2>&1 | tee "$tmp_log" >&2
build_status="${PIPESTATUS[0]}"
set -e

vendor_hash="$(
  sed -nE 's/.*got:[[:space:]]*(sha256-[A-Za-z0-9+/=]+).*/\1/p' "$tmp_log" |
    tail -n1
)"

if [[ -z "$vendor_hash" ]]; then
  echo >&2
  echo "error: could not extract vendorHash from nix build output" >&2

  if [[ "$build_status" -eq 0 ]]; then
    echo "The build unexpectedly succeeded with lib.fakeHash." >&2
  else
    echo "Look above for the nix error output." >&2
  fi

  exit 1
fi

printf '{\n  "version": "%s",\n  "hash": "%s",\n  "vendorHash": "%s"\n}\n' \
  "$new_version" "$src_hash" "$vendor_hash" > "$versions_file"

echo >&2
echo "Written to ${versions_file}" >&2
echo "Updated cc9s $current_version -> $new_version"
