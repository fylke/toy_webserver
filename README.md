# toy_webserver
An extremely simple web server for educational purposes. It exists in four different versions, with increasing complexity.

## Choose Your Path

- Use the Windows path if you do not use WSL.
- Use the WSL path if you work inside WSL or a VS Code WSL window.
- Both paths use the same container stack and the same shared token.

1. A TCP server that echoes what is sent to it, and then closes the connection
2. A TCP server that can serve multiple clients, but only one at a time
3. A fully parallel TCP server that still only echoes what it's sent
4. A basic HTTP server that understands GET

## Common test

```console
$ ct_run -dir . -logdir ct
```

## Build with rebar3 (minimal setup)

This repo now includes a minimal `rebar3` configuration that compiles the
existing top-level `.erl` files without moving them into `src/`.

```console
$ rebar3 compile
```

To clean generated build output:

```console
$ rebar3 clean
```

To run Common Test through rebar3 (recommended):

```console
$ rebar3 ct
```

You can still run Common Test the same way as before:

```console
$ ct_run -dir . -logdir ct
```

Or from an Erlang shell
```console
$ ct:run_test([{suite, "./server_SUITE"}, {logdir, "./ct"}]).
$ ct:run_test([{suite, "./server_SUITE"}, {logdir, "./ct"}, {group, server_tests}, {case, [tc_server_parallell_client_requests]} ]).
```

## Dev Container (OTP 26)

This repository includes a VS Code Dev Container configuration so students can
code in a reproducible Erlang environment.

1. Open the repository in VS Code.
2. Run "Dev Containers: Reopen in Container".
3. Open a terminal in the container and compile:

```console
$ erlc *.erl
```

4. Run tests:

```console
$ ct_run -dir . -logdir ct
```

5. Start the HTTP server from an Erlang shell:

```console
$ erl
1> http_server:start(8080).
```

### Runtime environment variables

- `HTTP_SERVER_ROOT`: Optional root path used for static content. Defaults to
	`.` if unset.
- `CLASS_SHARED_TOKEN`: Optional shared token for access control. If set,
	clients must send header `X-Class-Token: <token>`.

You can use [.env.example](.env.example) as a starting point for local values.
Copy it to `.env` when you want compose to pick up a stable token or host port
overrides automatically.

## Class hosting

Use this section when students need to reach the server running on your machine.

Use fixed ports for actual classroom access so students all connect to the same
stable address.

Use randomized ports for local validation runs, especially in WSL Podman, where
rootless port bindings can be left behind between repeated test runs.

### Instructor checklist

Before class:

1. Pick the Windows or WSL path you will actually use.
2. Set `CLASS_SHARED_TOKEN` to a fresh value for that session, either in your shell or in `.env` based on [.env.example](.env.example).
3. Start the stack.
4. Run the smoke test script and confirm `401` without a token and `200` with a token.
5. If students will connect over the internet, start the tunnel only after the smoke test passes.
6. Share the final URL, required header, and token with students.

After class:

1. Stop the stack.
2. Stop any active tunnel.
3. Discard the old token and use a new one next time.
4. If you used randomized ports for testing, clear those environment variables before the next fixed-port class run.

### Version 1: You do not use WSL

Use this path if you are working from Windows PowerShell or Windows Terminal.

1. Open a PowerShell window in the repository root.
2. Set a shared token:

```powershell
$env:CLASS_SHARED_TOKEN = "replace-this-before-class"
```

3. Start the stack:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-class.ps1
```

For testing with random host ports instead of the defaults:

```powershell
$env:RANDOMIZE_PORTS = "1"
powershell -ExecutionPolicy Bypass -File .\scripts\start-class.ps1
```

Smoke test the running stack:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-class.ps1 -Token $env:CLASS_SHARED_TOKEN
```

4. Stop the stack when done:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\stop-class.ps1
```

This starts:
- Erlang dev container (`erlang-dev`) where you run the server.
- Edge proxy (`edge-proxy`) on port `8081` that enforces `X-Class-Token`.

For real classroom use, keep the default fixed ports unless you have a specific
conflict on your machine.

### Version 2: You do use WSL

Use this path if you are working inside WSL or from a VS Code WSL window.

If `podman-compose` is not on your PATH, the WSL scripts will also use
`$HOME/.local/bin/podman-compose` when it exists.

This WSL Podman path was validated with `RANDOMIZE_PORTS=1`, which avoids stale
rootless port bindings during repeated local test runs.

1. Open a WSL shell in the repository root.
2. Set a shared token:

```console
$ export CLASS_SHARED_TOKEN="replace-this-before-class"
```

3. Start the stack:

```console
$ ./scripts/start-class.sh
```

For testing with random host ports instead of the defaults:

```console
$ RANDOMIZE_PORTS=1 ./scripts/start-class.sh
```

Smoke test the running stack:

```console
$ ./scripts/verify-class.sh "$CLASS_SHARED_TOKEN"
```

4. Stop the stack when done:

```console
$ ./scripts/stop-class.sh
```

This starts:
- Erlang dev container (`erlang-dev`) where you run the server.
- Edge proxy (`edge-proxy`) on port `8081` that enforces `X-Class-Token`.

For real classroom use, prefer the default fixed ports so your LAN address and
tunnel target stay predictable for students.

### What students use

Students on your local network can connect to:

- `http://<your-lan-ip>:8081/test.html`

If you enabled random ports for testing, use the `proxy=` port printed by the
start script instead of `8081`.

They must include header:

```text
X-Class-Token: <the shared token>
```

For internet access, point a tunnel provider at `http://localhost:8081` on
your machine. The token check still happens in the local edge proxy before
traffic reaches the Erlang server.

### Quick verification

```console
$ ./scripts/verify-class.sh "$CLASS_SHARED_TOKEN"
```

## Debugging TCP connections

```console
netstat -ano | Select-String "8080"
```
