#!/usr/bin/env sh
set -eu

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

HTTP_PORT="${HOST_HTTP_PORT:-}"
if [ -z "$HTTP_PORT" ]; then
	HTTP_PORT="$($CONTAINER_CMD port toy_webserver_dev 8080 | awk -F: 'NR == 1 {print $NF}')"
fi

if [ -z "$HTTP_PORT" ]; then
	echo "Could not determine host HTTP port." >&2
	exit 1
fi

RESPONSE_CODE="$(curl -s -o /tmp/toy_webserver-response.out -w '%{http_code}' "http://127.0.0.1:${HTTP_PORT}/test.html")"
RESPONSE_BODY="$(head -c 120 /tmp/toy_webserver-response.out)"

printf 'HTTP_PORT=%s\n' "$HTTP_PORT"
printf 'RESPONSE_CODE=%s\n' "$RESPONSE_CODE"
printf 'RESPONSE_BODY=%s\n' "$RESPONSE_BODY"

[ "$RESPONSE_CODE" = "200" ]
