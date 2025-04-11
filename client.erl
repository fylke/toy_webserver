-module(client).
-compile([export_all, nowarn_export_all]).

start(Host, Port) ->
    %% Get IP address in Erlang tuple format.
    %% That is -type ip4_address() :: {0..255, 0..255, 0..255, 0..255} or
    %% -type ip6_address() :: {0..65535, 0..65535, 0..65535, 0..65535,
    %%                         0..65535, 0..65535, 0..65535, 0..65535}.
    {ok, Ip} = parse_ip(Host),
    {ok, Socket} = gen_tcp:connect(Ip, Port, [list, {packet, 0}]),
    {ok, {LocalIp, LocalPort}} = inet:sockname(Socket),
    {ok, {PeerIp, PeerPort}} = inet:peername(Socket),
    Pid = self(),
    ok = io:format("Client~p: Connected to IP ~p port ~p from IP ~p port ~p ~n",
                   [Pid, PeerIp, PeerPort, LocalIp, LocalPort]),
    ok = gen_tcp:send(Socket, "Hello"),
    ReplyFromServer =
        receive
            Reply ->
                ok = io:format("Client~p: Reply: ~p~n", [Pid, Reply]),
                Reply
        after
            timer:seconds(30) ->
                ok = io:format("Client~p: No data received.~n", [Pid]),
                {}
        end,
    ok = io:format("Client~p: Closing connection.~n", [Pid]),
    ok = gen_tcp:close(Socket),
    ReplyFromServer.

-spec parse_ip(list() | inet:ip_address()) -> inet:ip_address().
parse_ip(Ip = "localhost") ->
    %% String "localhost" address is accepted as is.
    {ok, Ip};
parse_ip(Ip) when is_list(Ip) ->
    %% A string that is parseable as IP is accepted.
    inet:parse_address(Ip);
parse_ip(Ip) when is_tuple(Ip) ->
    %% IP address in tuple format is also accepted.
    case inet:is_ipaddress(Ip) of
        true -> {ok, Ip};
        _Else -> {error, invalid_ip_address}
    end.