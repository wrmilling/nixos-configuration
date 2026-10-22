#!/usr/bin/env bash
# Deterministic checks on a pkg-update diff; prints a markdown report and
# exits 1 if any hard check fails.
set -euo pipefail

base=$(git merge-base "${1:?usage: precheck.sh <base-sha>}" HEAD)
fail=0
note() { echo "- $*"; }
bad() { echo "- **FAIL**: $*"; fail=1; }

echo "## Deterministic pre-checks"
echo

mapfile -t changed < <(git diff --name-only "$base...HEAD")
for f in "${changed[@]}"; do
  case "$f" in
    custom/pkgs/*/versions.json) ;;
    *) bad "unexpected file changed: \`$f\`" ;;
  esac
done

sri='^sha256-[A-Za-z0-9+/]{43}=$'
for f in "${changed[@]}"; do
  [[ "$f" == */versions.json ]] || continue
  old=$(git show "$base:$f" 2>/dev/null || echo '{}')
  new=$(cat "$f")

  old_v=$(jq -r '.version // empty' <<<"$old")
  new_v=$(jq -r '.version // empty' <<<"$new")
  if [[ -n "$old_v" && -n "$new_v" ]]; then
    note "\`$f\`: $old_v -> $new_v"
    if [[ "$old_v" == "$new_v" ]]; then
      note "version unchanged in \`$f\` (hash-only update)"
    elif [[ "$(printf '%s\n%s\n' "$old_v" "$new_v" | sort -V | tail -1)" != "$new_v" ]]; then
      bad "version went backwards in \`$f\`"
    fi
  fi

  old_keys=$(jq -c '[paths(scalars)] | map(map(tostring) | join(".")) | sort' <<<"$old")
  new_keys=$(jq -c '[paths(scalars)] | map(map(tostring) | join(".")) | sort' <<<"$new")
  [[ "$old_keys" == "$new_keys" ]] || bad "key set changed in \`$f\`: $old_keys -> $new_keys"

  while IFS=$'\t' read -r key val; do
    case "$key" in
      version | rev) continue ;;
    esac
    [[ "$val" =~ $sri ]] || bad "\`$f\` .$key is not a well-formed sha256 SRI hash: \`$val\`"
    old_val=$(jq -r --arg k "$key" 'getpath($k | split(".")) // empty' <<<"$old")
    if [[ "$val" == "$old_val" && "$old_v" != "$new_v" ]]; then
      bad "\`$f\` .$key is identical to the previous version's hash"
    fi
  done < <(jq -r 'paths(scalars) as $p | [($p | map(tostring) | join(".")), getpath($p)] | @tsv' <<<"$new")

  dups=$(jq -r '[paths(scalars) as $p | getpath($p) | select(type == "string" and startswith("sha256-"))] | group_by(.) | map(select(length > 1) | .[0]) | .[]' <<<"$new")
  [[ -z "$dups" ]] || bad "\`$f\` reuses the same hash for multiple keys: $dups"
done

echo
if ((fail)); then
  echo "Result: hard check(s) failed."
else
  echo "Result: all hard checks passed."
fi
exit "$fail"
