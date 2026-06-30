# toy_webserver
An extremely simple web server for educational purposes. It exists in four different versions, with increasing complexity.

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

## Debugging TCP connections

```console
netstat -ano | Select-String "8080"
```
