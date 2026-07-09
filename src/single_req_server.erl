-module(single_req_server).
-compile([export_all, nowarn_export_all]).

start(Port) ->
    {ok, ListenSocket} =
        gen_tcp:listen(Port,
                       [list,
                        {active, true},
                        {reuseaddr, true}]),
    listen_state(ListenSocket).

listen_state(Socket) ->
    Pid = self(),
    {ok, {ListenIp, ListenPort}} = inet:sockname(Socket),
    io:format("~p: Listening on IP ~p port ~p~n",
                   [Pid, ListenIp, ListenPort]),
    {ok, EstablishedSocket} = gen_tcp:accept(Socket),
    {ok, {LocalIp, LocalPort}} = inet:sockname(EstablishedSocket),
    {ok, {PeerIp, PeerPort}} = inet:peername(EstablishedSocket),
    io:format("~p: Accepted connection:~n  send IP ~p port ~p~n"
                "  recv IP ~p port ~p - Spawning handler...~n",
                [Pid, PeerIp, PeerPort, LocalIp, LocalPort]),
    ok = gen_tcp:close(Socket),
    established_state(EstablishedSocket).

established_state(Socket) ->
    Pid = self(),
    receive
        {tcp, Socket, StringMsg} ->
            io:format("~p: Received message: ~p~n", [Pid, StringMsg]),
            io:format("~p: Working on request...~n", [Pid]),
            %% Fake doing some work that takes time.
            timer:sleep(timer:seconds(3)),
            Reply = "Echo " ++ StringMsg,
            io:format("~p: Replying: ~p~n~n", [Pid, Reply]),
            ok = gen_tcp:send(Socket, Reply);
        {tcp_closed, Socket} ->
            io:format("~p: Client closed socket, shutting down...~n~n", [Pid])
    end,
    ok = gen_tcp:close(Socket).
