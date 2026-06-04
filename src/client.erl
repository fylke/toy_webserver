-module(client).

-compile([export_all, nowarn_export_all]).

start(IpString, Port, Data) ->
    %% Get IP address in Erlang tuple format.
    %% That is -type ip4_address() :: {0..255, 0..255, 0..255, 0..255} or
    %% -type ip6_address() :: {0..65535, 0..65535, 0..65535, 0..65535,
    %%                         0..65535, 0..65535, 0..65535, 0..65535}.
    {ok, Ip} = inet:parse_address(IpString),

    Connection = gen_tcp:connect(Ip, Port, [list, {packet, 0}]),
    handle_connection(Connection, Data).

handle_connection({error, Error}, _Data) ->
    {error, Error};
handle_connection({ok, Socket}, Data) ->
    {ok, {LocalIp, LocalPort}} = inet:sockname(Socket),
    {ok, {PeerIp, PeerPort}} = inet:peername(Socket),
    Pid = self(),
    io:format("Client~p: Connected to IP ~p port ~p from IP ~p port ~p ~n",
              [Pid, PeerIp, PeerPort, LocalIp, LocalPort]),
    ok = gen_tcp:send(Socket, Data),
    ReplyFromServer =
        receive
            Reply ->
                io:format("Client~p: Reply: ~p~n", [Pid, Reply]),
                {ok, Reply}
        after timer:seconds(30) ->
            io:format("Client~p: No data received.~n", [Pid]),
            {error, no_response}
        end,
    io:format("Client~p: Closing connection.~n", [Pid]),
    ok = gen_tcp:close(Socket),
    ReplyFromServer.
