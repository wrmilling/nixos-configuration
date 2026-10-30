#!/usr/bin/env bash
set -euo pipefail

print_help() {
  cat <<'EOF'
usage: update-obsidian-cert.sh [--context <ctx>] [--namespace <ns>] [--secret <name>] [-h|--help]

Copy a cert-manager TLS secret from the cluster into secrets/obsidian.yaml as
the Obsidian Local REST API plugin's cert and key, creating the file if it
doesn't exist. Leaves the file untouched if it already holds the same values.
Run `nh home switch .` and restart Obsidian afterwards to pick it up.

  --context <ctx>    kubectl context (default: current context)
  --namespace <ns>   namespace of the secret (default: cert-manager)
  --secret <name>    name of the kubernetes.io/tls secret (default: localhost-cert-tls)
EOF
}

context=""
namespace="cert-manager"
secret="localhost-cert-tls"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context) context="$2"; shift 2 ;;
    --namespace) namespace="$2"; shift 2 ;;
    --secret) secret="$2"; shift 2 ;;
    -h | --help) print_help; exit 0 ;;
    *) print_help >&2; exit 1 ;;
  esac
done

for cmd in kubectl sops jq; do
  command -v "$cmd" >/dev/null || { echo "$cmd not found on PATH" >&2; exit 1; }
done

cd "$(dirname "${BASH_SOURCE[0]}")/.."
file="secrets/obsidian.yaml"

new=$(
  kubectl ${context:+--context "$context"} get secret -n "$namespace" "$secret" -o json |
    jq '{"local-rest-api": {
      cert: (.data["tls.crt"] // error("secret has no tls.crt") | @base64d),
      privateKey: (.data["tls.key"] // error("secret has no tls.key") | @base64d)
    }}'
)

current='{}'
if [[ -e $file ]]; then
  current=$(sops decrypt --output-type json "$file")
fi

# Keep key material out of argv, where other processes could read it.
merged=$(jq -s '.[0] * .[1]' <(printf '%s' "$current") <(printf '%s' "$new"))
if jq -e -s '.[0] == .[1]' <(printf '%s' "$current") <(printf '%s' "$merged") >/dev/null; then
  echo "$file is already up to date"
  exit 0
fi

tmp=$(mktemp "$file.XXXXXX")
trap 'rm -f "$tmp"' EXIT
sops encrypt --filename-override "$file" --input-type json --output-type yaml /dev/stdin <<<"$merged" >"$tmp"
chmod 0644 "$tmp"
mv "$tmp" "$file"
echo "Updated $file from $namespace/$secret"
