#!/usr/bin/env sh
set -eu

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

$COMPOSE_CMD down