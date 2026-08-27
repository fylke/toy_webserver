#!/usr/bin/env sh
# Integration test for the class hosting scripts: brings the stack up with
# randomized ports, waits for the HTTP server, runs the smoke test, then
# tears the stack down and confirms cleanup.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
PORTS_FILE="$REPO_ROOT/.class-ports.env"

cleanup() {
	"$SCRIPT_DIR/stop-class.sh" >/dev/null 2>&1 || true
}
trap cleanup EXIT

export RANDOMIZE_PORTS=1
"$SCRIPT_DIR/start-class.sh"

if [ ! -f "$PORTS_FILE" ]; then
	echo "start-class.sh did not write $PORTS_FILE" >&2
	exit 1
fi

# shellcheck disable=SC1090
. "$PORTS_FILE"

READY=0
i=1
while [ "$i" -le 30 ]; do
	if curl -s -o /dev/null "http://127.0.0.1:${HOST_HTTP_PORT}/test.html"; then
		READY=1
		break
	fi
	i=$((i + 1))
	sleep 1
done

if [ "$READY" -ne 1 ]; then
	echo "HTTP server on port $HOST_HTTP_PORT never became ready" >&2
	exit 1
fi

"$SCRIPT_DIR/verify-class.sh"

"$SCRIPT_DIR/stop-class.sh"

if [ -f "$PORTS_FILE" ]; then
	echo "stop-class.sh did not remove $PORTS_FILE" >&2
	exit 1
fi

echo "Class stack setup test passed."
