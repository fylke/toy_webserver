#!/usr/bin/env sh
set -eu

find_free_port() {
	python3 - <<'PY'
import socket

sock = socket.socket()
sock.bind(("127.0.0.1", 0))
print(sock.getsockname()[1])
sock.close()
PY
}

if [ "${RANDOMIZE_PORTS:-0}" = "1" ]; then
	: "${HOST_TCP_PORT:=$(find_free_port)}"
	: "${HOST_HTTP_PORT:=$(find_free_port)}"
	export HOST_TCP_PORT HOST_HTTP_PORT
fi

if [ -n "${COMPOSE_CMD:-}" ]; then
	COMPOSE_CMD="$COMPOSE_CMD"
elif command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
	COMPOSE_CMD="podman compose"
elif command -v podman-compose >/dev/null 2>&1; then
	COMPOSE_CMD="podman-compose"
elif [ -x "$HOME/.local/bin/podman-compose" ]; then
	COMPOSE_CMD="$HOME/.local/bin/podman-compose"
else
	echo "No working compose command found. Install podman compose or podman-compose." >&2
	exit 1
fi

echo "Using host ports: tcp=${HOST_TCP_PORT:-7777} http=${HOST_HTTP_PORT:-8080}"

printf 'HOST_TCP_PORT=%s\nHOST_HTTP_PORT=%s\n' "${HOST_TCP_PORT:-7777}" "${HOST_HTTP_PORT:-8080}" > "$(dirname "$0")/../.class-ports.env"

$COMPOSE_CMD up -d --build
$COMPOSE_CMD exec -T erlang-dev sh -lc 'cd /workspace/toy_webserver && erlc *.erl && nohup erl -noshell -eval "http_server:start(8080)." >/tmp/http_server.log 2>&1 &'
