-module(date).
-export([rfc_2616/0,
         rfc_2616/1,
         iso_8601/0]).

rfc_2616() ->
    rfc_2616(calendar:universal_time()).

rfc_2616(_DateTime = {{Year, Month, Day}, {Hour, Min, Sec}}) ->
    %% {{Year, Month, Day}, {Hour, Min, Sec}} = calendar:universal_time(),
    DayOfWeek = calendar:day_of_the_week(Year, Month, Day),
    DateFormat = io_lib:format("~s, ~p ~s ~p ~.2.0w:~.2.0w:~.2.0w GMT",
                               [day_of_week(DayOfWeek), Day, month(Month),
                                Year, Hour, Min, Sec]),
    lists:flatten(DateFormat).


iso_8601() ->
    {{Year, Month, Day}, {Hour, Min, Sec}} = calendar:universal_time(),
    io_lib:format("~.4.0w-~.2.0w-~.2.0wT~.2.0w:~.2.0w:~.2.0w.0+00:00",
                  [Year, Month, Day, Hour, Min, Sec]).
                
month(1) -> "Jan";
month(2) -> "Feb";
month(3) -> "Mar";
month(4) -> "Apr";
month(5) -> "May";
month(6) -> "Jun";
month(7) -> "Jul";
month(8) -> "Aug";
month(9) -> "Sep";
month(10) -> "Okt";
month(11) -> "Nov";
month(12) -> "Dec".

day_of_week(1) -> "Mon";
day_of_week(2) -> "Tue";
day_of_week(3) -> "Wed";
day_of_week(4) -> "Thu";
day_of_week(5) -> "Fri";
day_of_week(6) -> "Sat";
day_of_week(7) -> "Sun".