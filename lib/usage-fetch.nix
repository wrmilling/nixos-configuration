{
  pkgs,
}:
{
  # Bash library sourced by statusline scripts. Exposes
  # `fetch_provider_usage`, `fetch_zclaude_usage`, `fetch_oclaude_usage`.
  #
  # Callers (the Claude Code statusline, the maki Lua plugin shim) pass a
  # keyfile path; when the keyfile is empty or unreadable the function falls
  # back to env vars already set by the wrapper (ZHIPU_API_KEY,
  # OPENCODE_API_KEY, OPENAI_API_KEY). Cached for 1800s, with a background
  # refresh throttled to once per 60s.
  script = pkgs.writeText "usage-fetch.sh" ''
    fetch_provider_usage() {
      keyfile=$1 cache_json=$2 cache_ts=$3 url=$4 five_h_jq=$5 seven_d_jq=$6
      provider=$7

      bearer=""
      if [ -n "$keyfile" ] && [ -r "$keyfile" ]; then
        bearer=$(cat "$keyfile")
      else
        case "$provider" in
          zclaude) bearer="''${ZHIPU_API_KEY:-}" ;;
          oclaude) bearer="''${OPENCODE_API_KEY:-}" ;;
          *) bearer="''${OPENAI_API_KEY:-}" ;;
        esac
      fi
      [ -n "$bearer" ] || return 0

      now=$(date +%s)
      ts=0
      if [ -f "$cache_ts" ]; then
        ts=$(cat "$cache_ts" 2>/dev/null || echo 0)
        case "$ts" in '''|*[!0-9]*) ts=0 ;; esac
      fi

      if [ -s "$cache_json" ] && [ $(( now - ts )) -lt 1800 ]; then
        v5h=$(jq -r "$five_h_jq" "$cache_json" 2>/dev/null || true)
        v7d=$(jq -r "$seven_d_jq" "$cache_json" 2>/dev/null || true)
        [ -z "$lim5h" ] && [ -n "$v5h" ] && lim5h=$(printf '%s' "$v5h" | awk '{printf "%d", $1+0}')
        [ -z "$lim7d" ] && [ -n "$v7d" ] && lim7d=$(printf '%s' "$v7d" | awk '{printf "%d", $1+0}')
      fi

      if [ $(( now - ts )) -ge 60 ]; then
        date +%s > "$cache_ts" 2>/dev/null || true
        (
          curl -sS -m 5 -H "Authorization: Bearer $bearer" \
            "$url" \
            -o "$cache_json.$$" \
            && mv "$cache_json.$$" "$cache_json"
        ) > /dev/null 2>&1 &
      fi
    }

    fetch_zclaude_usage() {
      fetch_provider_usage "$1" "$2" "$3" \
        "https://api.z.ai/api/monitor/usage/quota/limit" \
        '[.data.limits[]? | select(.type == "TOKENS_LIMIT" and .unit == 3) | .percentage][0] // empty' \
        '[.data.limits[]? | select(.type == "TOKENS_LIMIT" and .unit == 6) | .percentage][0] // empty' \
        zclaude
    }

    fetch_oclaude_usage() {
      fetch_provider_usage "$1" "$2" "$3" \
        "https://opencode.ai/zen/go/v1/usage" \
        '.usage.rolling.percent // empty' \
        '.usage.weekly.percent // empty' \
        oclaude
    }
  '';
}
