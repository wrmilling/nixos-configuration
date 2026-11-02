#!/usr/bin/env bash
set -euo pipefail

print_help() {
  cat <<'EOF'
usage: update-obsidian-secrets.sh [--context <ctx>] [--namespace <ns>] [--secret <name>] [--rotate-api-key] [-h|--help]

Write the Obsidian Local REST API plugin's secrets into secrets/obsidian.yaml,
creating the file if it doesn't exist:
  - cert and key, copied from a cert-manager TLS secret in the cluster
  - API key, generated once and kept on later runs unless --rotate-api-key
Leaves the file untouched if nothing changed. Run `nh home switch .` and
restart Obsidian afterwards to pick it up.

  --context <ctx>    kubectl context (default: current context)
  --namespace <ns>   namespace of the secret (default: cert-manager)
  --secret <name>    name of the kubernetes.io/tls secret (default: localhost-cert-tls)
  --rotate-api-key   replace the existing API key with a new one
EOF
}

context=""
namespace="cert-manager"
secret="localhost-cert-tls"
rotate=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context) context="$2"; shift 2 ;;
    --namespace) namespace="$2"; shift 2 ;;
    --secret) secret="$2"; shift 2 ;;
    --rotate-api-key) rotate=true; shift ;;
    -h | --help) print_help; exit 0 ;;
    *) print_help >&2; exit 1 ;;
  esac
done

for cmd in kubectl sops jq od; do
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

generated=$(od -An -tx1 -N32 /dev/urandom | tr -d ' \n')

# Keep key material out of argv, where other processes could read it.
merged=$(
  jq -s --argjson rotate "$rotate" '
    .[2] as $generated
    | (.[0] * .[1])
    | ."local-rest-api".apiKey |= (if $rotate or (. // "") == "" then $generated else . end)
  ' <(printf '%s' "$current") <(printf '%s' "$new") <(printf '"%s"' "$generated")
)
if jq -e -s '.[0] == .[1]' <(printf '%s' "$current") <(printf '%s' "$merged") >/dev/null; then
  echo "$file is already up to date"
  exit 0
fi

tmp=$(mktemp "$file.XXXXXX")
trap 'rm -f "$tmp"' EXIT
sops encrypt --filename-override "$file" --input-type json --output-type yaml /dev/stdin <<<"$merged" >"$tmp"
chmod 0644 "$tmp"
mv "$tmp" "$file"
echo "Updated $file"
