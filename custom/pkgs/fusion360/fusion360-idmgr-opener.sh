#!/usr/bin/env bash
set -euo pipefail

data_root="${XDG_DATA_HOME:-$HOME/.local/share}/fusion360"
prefix="$data_root/wineprefix"
export WINEPREFIX="$prefix"

idmgr_exe="$(find "$prefix" -iname AdskIdentityManager.exe 2>/dev/null | head -n1)"
if [ -z "$idmgr_exe" ]; then
  echo "error: AdskIdentityManager.exe not found; run 'fusion360' first to install it." >&2
  exit 1
fi

exec wine "$idmgr_exe" "$@"
