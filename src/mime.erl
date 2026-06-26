-module(mime).
-export([get/1]).

get(Filename) ->
    from_ext(filename:extension(Filename)).

from_ext([]) -> "text/html; charset=utf-8";
from_ext(".html") -> "text/html; charset=utf-8";
from_ext(".css") -> "text/css";
from_ext(".gif") -> "image/gif";
from_ext(".jpg") -> "image/jpeg";
from_ext(".jpeg") -> "image/jpeg";
from_ext(".png") -> "image/png";
from_ext(".ico") -> "image/vnd.microsoft.icon";
from_ext(".js") -> "text/javascript";
from_ext(".json") -> "application/json";
from_ext(".txt") -> "text/plain";
%% For unknown types, just serve as plain text.
from_ext(_) -> "text/plain".