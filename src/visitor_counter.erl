-module(visitor_counter).
-export([start/0]).
-export([reset/0]).
-export([get_count/0]).
-export([stop/0]).
-export([increment/0]).
-export([increment/1]).

start() ->
    case whereis(?MODULE) of
      undefined ->
        F = fun() -> 
            loop(0)
        end,
        Pid = spawn(F),
        register(?MODULE, Pid);
    _Pid ->
        already_started
    end.

get_count() ->
    ?MODULE ! {get_count, self()},
    receive
      {count, Visitors} ->
        Visitors
    after 1000 ->
        error_no_reply
    end.

reset() ->
    ?MODULE ! reset,
    ok.

stop() ->
    ?MODULE ! stop,
    ok.

increment() ->
    ?MODULE ! increment,
    ok.

increment(N) ->
    ?MODULE ! {increment, N},
    ok.

loop(State) ->
    receive
        increment ->
            loop(State + 1);
        {increment, N} ->
            loop(State + N);
        reset ->
            loop(0);
        {get_count, Pid} ->
            Pid ! {count, State},
            loop(State);
        stop ->
            ok
    after timer:minutes(30) ->
        ok
    end.