-module(helper).
-export([round1dec/1, check_time/2, is_light_avaliable/1, get_time/0]).

% Dedfines 
-define(max_temp, 34).
-define(min_temp, 18).


-define(reading_brightness,500).
-define(nigt_brightness,50).
-define(min_brightness,0). %lampy wyłączone
-define(max_bulb_power,500).


round1dec(Number) ->
    P = math:pow(10, 1),
    floor(Number * P) / P.

check_time({Start_HM},{Stop_HM}) ->
    {_,{H,M,_}} = erlang:localtime(),
    HM = H * 60 + M,
    if
        Start_HM =< Stop_HM ->
            if
                HM >= Start_HM andalso HM < Stop_HM ->
                    true;
                true ->
                    false
            end;
        true ->
            if
                HM > Stop_HM andalso HM =< Start_HM ->
                    false;
                true ->
                    true
            end
    end.


is_light_avaliable(Light) -> 
    if 
        Light < ?min_brightness ->
            ?min_brightness;

        true -> 
            Light
    end.




get_time() ->
    Time = string:left(io:get_line("Set time (gg:mm): "),5),
    Test = re:run(Time, "^[0-9]{2}:[0-9]{2}$"),
    if
        Test =:= nomatch ->
            io:format("Wrong input data!\n"),
            get_time();

        true -> 
            {H, _} = string:to_integer(string:left(Time,2)),
            {M, _} = string:to_integer(string:right(Time,2)),
            if
                H > 23 ->
                    Ret_H = 0;

                H < 0 ->
                    Ret_H = 0;

                true -> 
                    Ret_H = H
            end,
            if
                M > 59 ->
                    Ret_M = 0;

                M < 0 ->
                    Ret_M = 0;

                true -> 
                    Ret_M = M
            end,
            {Ret_H, Ret_M}
    end.
