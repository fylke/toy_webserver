-module(server_SUITE).
-compile([export_all, nowarn_export_all]).

-include_lib("stdlib/include/assert.hrl").

all() -> [ {group, GroupName} || {GroupName, _Opt, List} <- groups(), length(List) > 0 ].

groups() ->
    ServerTests = [tc_server_onetime_request,
                   tc_server_multiple_client_requests,
                   tc_server_parallell_client_requests],
    HttpUtil = [tc_http_split_headers,
                tc_http_make_header_text,
                tc_rfc_2616_date,
                tc_httpc_bug_header],
    HttpServer = [tc_http_server_get],
    [{server_tests, [], ServerTests},
     {http_util, [parallel], HttpUtil},
     {http_server, [], HttpServer}].

init_per_suite(Config) ->
    %% For using Erlang's httpc module in test
    inets:start(),
    {ok, Cwd} = file:get_cwd(),
    %% Normalize the repo root so the suite works from Docker or any other
    %% checkout location, and preserve the previous process-wide env values.
    Root = find_project_root(Cwd),
    PrevRoot = os:getenv("HTTP_SERVER_ROOT"),
    PrevToken = os:getenv("CLASS_SHARED_TOKEN"),
    true = os:putenv("HTTP_SERVER_ROOT", Root),
    os:unsetenv("CLASS_SHARED_TOKEN"),
    Config ++ [{host, "127.0.0.1"},
               {port, 7777},
               {prev_http_server_root, PrevRoot},
               {prev_class_shared_token, PrevToken}].

end_per_suite(Config) ->
    restore_env("HTTP_SERVER_ROOT", proplists:get_value(prev_http_server_root, Config)),
    restore_env("CLASS_SHARED_TOKEN", proplists:get_value(prev_class_shared_token, Config)),
    inets:stop(),
    ok.

tc_server_onetime_request(Config) ->
    Host = proplists:get_value(host, Config),
    Port = proplists:get_value(port, Config),
    spawn_link(single_req_server, start, [Port]),
    timer:sleep(100), %% Give server some time to start up before clients connect.
    {tcp, _Socket, "Echo Hello"} = client:start(Host, Port, "Hello"),
    {error, econnrefused} = client:start(Host, Port, "Hello"),
    ok.

tc_server_multiple_client_requests(Config) ->
    Host = proplists:get_value(host, Config),
    Port = proplists:get_value(port, Config),
    spawn_link(multi_req_server, start, [Port]),
    timer:sleep(100), %% Give server some time to start up before clients connect.
    {tcp, _Socket1, "Echo Hello"} = client:start(Host, Port, "Hello"),
    {tcp, _Socket2, "Echo Hello"} = client:start(Host, Port, "Hello"),
    multi_req_server ! stop,
    ok.

tc_server_parallell_client_requests(Config) ->
    Host = proplists:get_value(host, Config),
    Port = proplists:get_value(port, Config),
    spawn_link(parallel_server, start, [Port]),
    timer:sleep(100), %% Give server some time to start up before clients connect.
    TcPid = self(),
    NoOfRequests = 5,
    [ spawn_link(fun() ->
                         timer:sleep(N * 10),
                         Reply = client:start(Host, Port, "Hello"),
                         TcPid ! Reply
                 end)
      || N <- lists:seq(1, NoOfRequests) ],
    receive_replies(NoOfRequests),
    ct:pal("Got replies from server for all client requests."),
    parallel_server ! stop,
    ok.

tc_http_server_get(Config) ->
    Host = proplists:get_value(host, Config),
    Port = proplists:get_value(port, Config),
    spawn_link(http_server, start, [Port]),
    Url = lists:concat(["http://", Host, ":", Port, "/test.html"]),
    ct:pal("Url ~p~n", [Url]),
    {ok, Reply} = httpc:request(Url),
    ct:pal("Reply ~p~n", [Reply]),
    {StatusLine, Headers, Body} = Reply,
    ?assertEqual({"HTTP/1.1", 200, "OK"}, StatusLine),
    [{"date", _Date},
     {"content-type", "text/html; charset=utf-8"}] = Headers,
    ?assertEqual("<!DOCTYPE html><html>Test content</html>", Body),
    http_server ! stop,
    ok.

tc_http_split_headers(_Config) ->
    Request =
        "GET /path/to/file.html HTTP/1.1\r\nFrom: someuser@example.com\r\nUse"
        "r-Agent: Toy Client\r\n\r\n",
    {Resource, Headers} = http:parse_request(Request),
    ct:pal("Resource ~p~n", [Resource]),
    ct:pal("Headers ~p~n", [Headers]),
    ?assertEqual({"GET", "/path/to/file.html", "HTTP/1.1"}, Resource),
    ?assertEqual(#{
                   "From" => "someuser@example.com",
                   "User-Agent" => "Toy Client"
                  },
                 Headers),
    ok.

tc_httpc_bug_header(_Config) ->
    %% Workaround for bug in Erlang OTP 24 httpc:reqest/1 sending
    %% empty transfer encoding header.
    %% See: https://github.com/erlang/otp/issues/10065
    Request = "GET /test.html HTTP/1.1\r\ncontent-length: 0\r\nte: \r\n"
              "host: localhost:7777\r\nconnection: keep-alive\r\n\r\n",
    {Resource, Headers} = http:parse_request(Request),
    ct:pal("Resource ~p~n", [Resource]),
    ct:pal("Headers ~p~n", [Headers]),
    ?assertEqual({"GET", "/test.html", "HTTP/1.1"}, Resource),
    ?assertEqual(#{
                   "content-length" => "0",
                   "host" => "localhost:7777",
                   "connection" => "keep-alive",
                   "te" => "bogus"
                  },
                 Headers),
    ok.

tc_http_make_header_text(_Config) ->
    HeaderText =
        http:make_header_text(200,
                              #{
                                "From" => "someuser@example.com",
                                "User-Agent" => "Toy Client"
                               }),
    Expected = "HTTP/1.1 200 OK\r\nFrom: someuser@example.com\r\nUser-Agent: Toy Client\r\n\r\n",
    ?assertEqual(Expected, HeaderText),
    ok.

tc_rfc_2616_date(_Config) ->
    Expected = "Fri, 31 Dec 1999 23:59:58 GMT",
    RfcDate = date:rfc_2616({{1999, 12, 31}, {23, 59, 58}}),
    ?assertEqual(Expected, RfcDate),
    ok.

%% TODO: mime test

%% Helper functions
receive_replies(_N = 0) ->
    ok;
receive_replies(N) when is_integer(N), N > 0 ->
    receive
        {tcp, _Socket, "Echo Hello"} ->
            ct:pal("~p replies left~n", [N])
    after
        timer:seconds(5) ->
            ct:fail("Did not get reply from request ~p~n", [N])
    end,
    receive_replies(N - 1).

find_project_root(StartDir) ->
    find_project_root(StartDir, 0).

find_project_root(Dir, Depth) when Depth < 10 ->
    Probe = filename:join([Dir, "content", "test.html"]),
    case filelib:is_file(Probe) of
        true ->
            Dir;
        false ->
            Parent = filename:dirname(Dir),
            case Parent =:= Dir of
                true ->
                    element(2, file:get_cwd());
                false ->
                    find_project_root(Parent, Depth + 1)
            end
    end;
find_project_root(_Dir, _Depth) ->
    {ok, Cwd} = file:get_cwd(),
    Cwd.

restore_env(Name, false) ->
    os:unsetenv(Name);
restore_env(Name, Value) ->
    true = os:putenv(Name, Value).
