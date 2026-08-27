#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PORTS_FILE="$SCRIPT_DIR/../.class-ports.env"

if [ -f "$PORTS_FILE" ]; then
	# shellcheck disable=SC1090
	. "$PORTS_FILE"
fi

HTTP_PORT="${HOST_HTTP_PORT:-8080}"

RESPONSE_CODE="$(curl -s -o /tmp/toy_webserver-response.out -w '%{http_code}' "http://127.0.0.1:${HTTP_PORT}/test.html")"
RESPONSE_BODY="$(head -c 120 /tmp/toy_webserver-response.out)"

printf 'HTTP_PORT=%s\n' "$HTTP_PORT"
printf 'RESPONSE_CODE=%s\n' "$RESPONSE_CODE"
printf 'RESPONSE_BODY=%s\n' "$RESPONSE_BODY"

[ "$RESPONSE_CODE" = "200" ]
