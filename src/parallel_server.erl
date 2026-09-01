-module(parallel_server).
-compile([export_all, nowarn_export_all]).

start(Port) ->
    register(parallel_server, self()),
    {ok, ListenSocket} =
        gen_tcp:listen(Port,
                       [list,
                        {active, false},
                        {reuseaddr, true}]),
    listen_state(ListenSocket).

listen_state(Socket) ->
    Pid = self(),
    %% Check if we've received message to shut down server, otherwise listen for connections.
    receive
        stop ->
            io:format("~p: Received 'stop' - shutting down...~n~n", [Pid]),
            ok = gen_tcp:close(Socket),
            exit(normal)
    after
        0 ->
            {ok, {ListenIp, ListenPort}} = inet:sockname(Socket),
            io:format("~p: Listening on IP ~p port ~p~n",
                           [Pid, ListenIp, ListenPort])
    end,
    case gen_tcp:accept(Socket, timer:seconds(30)) of
        %% A client connected, handle request.
        {ok, EstablishedSocket} ->
            {ok, {LocalIp, LocalPort}} = inet:sockname(EstablishedSocket),
            {ok, {PeerIp, PeerPort}} = inet:peername(EstablishedSocket),
            io:format("~p: Accepted connection:~n  send IP ~p port ~p~n"
                      "  recv IP ~p port ~p - Spawning handler...~n",
                      [Pid, PeerIp, PeerPort, LocalIp, LocalPort]),
            HandlerPid = spawn(?MODULE, established_state, [EstablishedSocket]),
            %% Whichever process accepts TCP connection owns the socket, and also gets
            %% any data client sends, so need to handover socket to handler process.
            ok = gen_tcp:controlling_process(EstablishedSocket, HandlerPid),
            HandlerPid ! activate;
        %% No client connected for a while, time out so we can check for stop
        %% message in next loop iteration.
        {error, timeout} ->
            io:format("~p: No client request to handle...~n~n", [Pid])
    end,
    ?MODULE:listen_state(Socket).

established_state(Socket) ->
    Pid = self(),
    receive
        activate ->
            ok = inet:setopts(Socket, [{active, true}]),
            established_state(Socket);
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
    after
        timer:seconds(30) ->
            io:format("~p: No data received from client~n~n", [Pid])
    end,
    ok = gen_tcp:close(Socket).
