#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$dir/../lib/update-loose-assets.sh"

update_obsidian_plugin "obsidian-tasks-group/obsidian-tasks" "obsidian-tasks"
