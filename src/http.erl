-module(http).

-export([handle_request/1,
         parse_request/1,
         make_header_text/2]).

-include("http_server_config.hrl").

handle_request(Request) ->
    ct:pal("Request: ~p~n", [Request]),
    %% We only support HTTP get right now
    {{_Method = "GET", Resource, "HTTP/1.1"}, RequestHeaders} = parse_request(Request),
    ct:pal("http: Resource: ~p~n", [Resource]),
    ct:pal("http: RequestHeaders: ~p~n", [RequestHeaders]),
    {Header, ResponseContent} =
        %% TODO: 404/500 if not found
        case get_content(Resource) of
            {ok, Content} ->
                Mime = mime:get(Resource),
                io:format("http: Mime: ~p~n", [Mime]),
                ResponseHeaders = #{"Date" => date:rfc_2616(),
                                    "Content-Type" => Mime},
                {make_header_text(200, ResponseHeaders), Content};
            {error, enoent} ->
                ResponseHeaders = #{"Date" => date:rfc_2616(),
                                    "Content-Type" => "text/html"},
                Content = <<"404 Not Found">>,
                {make_header_text(404, ResponseHeaders), Content};
            _Else ->
                ResponseHeaders = #{"Date" => date:rfc_2616(),
                                    "Content-Type" => "text/html"},
                Content = <<"500 Internal Server Error">>,
                {make_header_text(500, ResponseHeaders), Content}
        end,
    lists:concat([Header, binary_to_list(ResponseContent)]).

parse_request(Request) ->
    Tokens = string:split(string:trim(Request), "\r\n", all),
    [Resource | HeaderText] = lists:map(fun string:trim/1, Tokens),
    {parse_resource(Resource), parse_headers(HeaderText)}.

parse_resource(Resource) ->
    [Method, File, Protocol = "HTTP/1.1"] = string:split(Resource, " ", all),
    {Method, File, Protocol}.

parse_headers(HeaderText) ->
    HeaderPropList =
        lists:map(fun("te:") ->
                    %% Workaround for bug in Erlang OTP 24 httpc:reqest/1 sending
                    %% empty transfer encoding header.
                    %% See: https://github.com/erlang/otp/issues/10065
                    {"te", "bogus"};
                     (H) ->
                          [Key, Val] = string:split(H, ": "),
                          {Key, Val}
                  end,
                  HeaderText),
    maps:from_list(HeaderPropList).

make_header_text(ResponseCode, Headers) ->
    ResponseCodeText = make_response_code(ResponseCode),
    HeaderText = [ lists:concat([Key, ": ", Val, "\r\n"])
                   || {Key, Val} <- maps:to_list(Headers) ],
    lists:flatten([ResponseCodeText | HeaderText]) ++ "\r\n".

make_response_code(200) -> "HTTP/1.1 200 OK\r\n";
make_response_code(404) -> "HTTP/1.1 404 Not Found\r\n";
make_response_code(500) -> "HTTP/1.1 500 Internal Server Error\r\n".

get_content("/") ->
    % visitor_counter:increment(),
    FileName = "index.html",
    Resource = server_root() ++ "/content/" ++ FileName,
    file:read_file(Resource);
get_content([$/ | FileName]) ->
    % visitor_counter:increment(),
    Resource = server_root() ++ "/content/" ++ FileName,
    file:read_file(Resource);
get_content(_) ->
    {error, enoent}.

server_root() ->
    case os:getenv("HTTP_SERVER_ROOT") of
        false ->
            ?DEFAULT_HTTP_SERVER_ROOT;
        "" ->
            ?DEFAULT_HTTP_SERVER_ROOT;
        Root ->
            Root
    end.
