#!/usr/bin/env bash
set -euo pipefail

BASE_URL="http://127.0.0.1:8000"
WRITE_ENABLED=false
MAX_WRITES=5

usage() {
  cat <<'EOF'
Usage: bash api-validation.sh [--target http://127.0.0.1:8000] [--execute-writes]

Default mode is dry-run: it performs only the initial GET and displays the
planned POST checks. POST requests require --execute-writes.

Only localhost / loopback targets are accepted.
EOF
}

while (($#)); do
  case "$1" in
    --target)
      [[ $# -ge 2 ]] || { echo "Missing value for --target" >&2; exit 2; }
      BASE_URL="${2%/}"
      shift 2
      ;;
    --execute-writes)
      WRITE_ENABLED=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Deliberately restrict this portfolio example to local lab targets.
case "$BASE_URL" in
  http://localhost:*|https://localhost:*|http://127.0.0.1:*|https://127.0.0.1:*|http://[::1]:*|https://[::1]:*|http://localhost|https://localhost|http://127.0.0.1|https://127.0.0.1|http://[::1]|https://[::1])
    ;;
  *)
    echo "Blocked: target must be localhost / loopback. Got: $BASE_URL" >&2
    exit 1
    ;;
esac

API_WRITE="$BASE_URL/api/ratings"
API_READ="$BASE_URL/api/ratings/1"
COOKIE_JAR="$(mktemp)"
HTML_FILE="$(mktemp)"
BODY_FILE="$(mktemp)"
cleanup() { rm -f "$COOKIE_JAR" "$HTML_FILE" "$BODY_FILE"; }
trap cleanup EXIT

UA="api-security-testing-lab/1.0"
echo "[*] Target: $BASE_URL"
echo "[*] Fetching lab home page..."

curl -fsS -c "$COOKIE_JAR" -A "$UA" \
  -H 'Accept: text/html' "$BASE_URL/" -o "$HTML_FILE" || {
    echo "Could not reach local lab. Start your test application first." >&2
    exit 1
  }

CSRF_TOKEN="$(grep -oP '<meta name="csrf-token" content="\K[^"]+' "$HTML_FILE" | head -n1 || true)"

if [[ -n "$CSRF_TOKEN" ]]; then
  echo "[+] CSRF meta token detected."
else
  echo "[i] No CSRF meta token detected; lab may use another mechanism."
fi

api_read() {
  curl -sS -b "$COOKIE_JAR" -c "$COOKIE_JAR" -A "$UA" \
    --max-time 15 -H 'Accept: application/json' \
    -o "$BODY_FILE" -w 'HTTP %{http_code} | %{content_type} | %{size_download} bytes\n' "$1"
  head -c 500 "$BODY_FILE"
  echo
}

echo
echo "[*] Read-only response check:"
api_read "$API_READ"

if [[ "$WRITE_ENABLED" != true ]]; then
  echo
  echo "[DRY RUN] No POST request was sent."
  echo "To run up to $MAX_WRITES local lab submissions, pass --execute-writes."
  exit 0
fi

echo
echo "[!] Write checks enabled for local lab only (maximum $MAX_WRITES)."
for i in $(seq 1 "$MAX_WRITES"); do
  payload="$(printf '{"resource_id":1,"rating":3,"comment":"authorized-lab-check-%s","_token":"%s"}' "$i" "$CSRF_TOKEN")"
  curl -sS -b "$COOKIE_JAR" -c "$COOKIE_JAR" -A "$UA" \
    --max-time 15 -X POST \
    -H 'X-Requested-With: XMLHttpRequest' \
    -H "X-CSRF-TOKEN: $CSRF_TOKEN" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -d "$payload" -o "$BODY_FILE" \
    -w "POST $i: HTTP %{http_code}\n" "$API_WRITE"
  head -c 250 "$BODY_FILE"
  echo
done

echo
echo "[*] Reading lab result after write checks:"
api_read "$API_READ"
