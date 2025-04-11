-module(parallel_server).
-export([start/1, established_state/2]).

start(Port) ->
    register(parallel_server, self()),
    {ok, ListenSocket} =
        gen_tcp:listen(Port,
                       [list,
                        {packet, 0},
                        {active, true},
                        {reuseaddr, true}]),
    listen_state(ListenSocket, 1).

listen_state(Socket, HandlerCount) ->
    %% Check if we've received message to shut down server, otherwise listen
    %% for connections.
    receive
        stop ->
            io:format("ListeningServer: Received 'stop' - shutting down...~n~n"),
            ok = gen_tcp:close(Socket),
            exit(normal)
    after
        0 ->
            {ok, {ListenIp, ListenPort}} = inet:sockname(Socket),
            ok = io:format("Server: Listening on IP ~p port ~p~n",
                           [ListenIp, ListenPort])
    end,
    case gen_tcp:accept(Socket, timer:seconds(30)) of
        %% A client connected, handle request.
        {ok, EstablishedSocket} ->
            {ok, {LocalIp, LocalPort}} = inet:sockname(EstablishedSocket),
            {ok, {PeerIp, PeerPort}} = inet:peername(EstablishedSocket),
            %% FIXME I'm sure there is a tidier way...
            HandlerName = lists:flatten("Server" ++ io_lib:format("~3..0w", [HandlerCount])),
            io:format("ListeningServer: Accepted connection from IP ~p port ~p on IP "
                      "~p port ~p - Spawning handler...~n",
                      [PeerIp, PeerPort, LocalIp, LocalPort]),
            spawn_link(?MODULE, established_state, [EstablishedSocket, HandlerName]);
        %% No client connected for a while, time out so we can check for stop
        %% message in next loop iteration.
        {error, timeout} ->
            io:format("ListeningServer: No client request to handle...~n~n")
    end,
    listen_state(Socket, HandlerCount + 1).

established_state(Socket, ServerName) ->
    receive
       {tcp, Socket, StringMsg} ->
            io:format("~p: Received message: ~p~n", [ServerName, StringMsg]),
            io:format("~p: Working on request...~n", [ServerName]),
            %% Fake doing some work that takes time.
            timer:sleep(timer:seconds(3)),
            Reply = "Echo " ++ StringMsg,
            io:format("~p: Replying: ~p~n~n", [ServerName, Reply]),
            ok = gen_tcp:send(Socket, Reply);
        {tcp_closed, Socket} ->
            io:format("~p: Client closed socket, shutting down...~n~n", [ServerName])
    after
        timer:seconds(30) ->
            io:format("~p: No data received from client~n~n", [ServerName])
    end,
    ok = gen_tcp:close(Socket).
