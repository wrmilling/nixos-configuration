#!/usr/bin/env bash
set -euo pipefail

# mcpelauncher-ui-qt has no version of its own -- it inherits `version` from
# mcpelauncher-client-git and is bumped in lock-step with it (same upstream
# "v<version>" tag, on a sibling repo). That package's update script bumps
# both, so just run it.
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$dir/../mcpelauncher-client/update.sh" "$@"
