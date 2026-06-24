#!/usr/bin/env sh
set -eu

TOKEN="${1:-${CLASS_SHARED_TOKEN:-}}"

if [ -z "$TOKEN" ]; then
	echo "Provide the shared token as the first argument or CLASS_SHARED_TOKEN." >&2
	exit 1
fi

if [ -n "${CONTAINER_CMD:-}" ]; then
	CONTAINER_CMD="$CONTAINER_CMD"
elif command -v podman >/dev/null 2>&1; then
	CONTAINER_CMD="podman"
elif command -v docker >/dev/null 2>&1; then
	CONTAINER_CMD="docker"
else
	echo "No container CLI found. Install podman or docker." >&2
	exit 1
fi

PROXY_PORT="${HOST_PROXY_PORT:-}"
if [ -z "$PROXY_PORT" ]; then
	PROXY_PORT="$($CONTAINER_CMD port toy_webserver_edge 8081 | awk -F: 'NR == 1 {print $NF}')"
fi

if [ -z "$PROXY_PORT" ]; then
	echo "Could not determine host proxy port." >&2
	exit 1
fi

NO_TOKEN_CODE="$(curl -s -o /tmp/toy_webserver-no-token.out -w '%{http_code}' "http://127.0.0.1:${PROXY_PORT}/test.html")"
WITH_TOKEN_CODE="$(curl -s -o /tmp/toy_webserver-with-token.out -w '%{http_code}' -H "X-Class-Token: ${TOKEN}" "http://127.0.0.1:${PROXY_PORT}/test.html")"
WITH_TOKEN_BODY="$(head -c 120 /tmp/toy_webserver-with-token.out)"

printf 'PROXY_PORT=%s\n' "$PROXY_PORT"
printf 'NO_TOKEN_CODE=%s\n' "$NO_TOKEN_CODE"
printf 'WITH_TOKEN_CODE=%s\n' "$WITH_TOKEN_CODE"
printf 'WITH_TOKEN_BODY=%s\n' "$WITH_TOKEN_BODY"

[ "$NO_TOKEN_CODE" = "401" ] && [ "$WITH_TOKEN_CODE" = "200" ]
