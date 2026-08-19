#!/usr/bin/env bash
# Post a PR review to the Forgejo API. Claude invokes this as a single tool call
# instead of composing a jq+curl payload inline -- embedding a long markdown
# review body (backticks, code fences, $-signs) in a shell variable/heredoc is
# fragile and a common source of wasted retry turns.
#
# Usage: post-review.sh <APPROVED|REQUEST_CHANGES> <body-file>
#
# Required env: API, REPO, PR, CLAUDE_REVIEWER_TOKEN

set -euo pipefail

event="${1:?usage: post-review.sh <APPROVED|REQUEST_CHANGES> <body-file>}"
body_file="${2:?usage: post-review.sh <APPROVED|REQUEST_CHANGES> <body-file>}"

if [[ "$event" != "APPROVED" && "$event" != "REQUEST_CHANGES" ]]; then
  echo "ERROR: event must be APPROVED or REQUEST_CHANGES, got: $event" >&2
  exit 1
fi

if [[ ! -f "$body_file" ]]; then
  echo "ERROR: body file not found: $body_file" >&2
  exit 1
fi

payload=$(jq -n --arg event "$event" --rawfile body "$body_file" '{event: $event, body: $body}')
curl -sf -X POST -H "Authorization: token $CLAUDE_REVIEWER_TOKEN" -H "Content-Type: application/json" \
  "$API/repos/$REPO/pulls/$PR/reviews" -d "$payload"
