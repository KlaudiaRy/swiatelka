-module(display).
-export([draw_panel/5]).

-import(helper, [round1dec/1]).

draw_panel(Daylight,Actual, Given, Sens_damage, {Stat1, {{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}}) ->
    io:format("\t ==========================\n"),
    io:format("\t||Naturalna jasnosc    ~p lx ||\n", [Daylight]),
    io:format("\t||Potrzebne oswietlenie   ~p lx ||\n", [Given]),
    io:format("\t||automatyczne oswietlenie    ~p lx||\n", [Actual]),
    io:format("\t||Stan czujników       ~s    ||\n", [Sens_damage]),
    io:format("\t||Lamp             ~s    ||\n", [add_space_after(Stat1)]),
    io:format("\t||Lamp Start      ~s   ||\n", [time_string({Given_start_H, Given_start_M})]),
    io:format("\t||Lamp Stop       ~s   ||\n", [time_string({Given_stop_H, Given_stop_M})]),
    time_hm(),
    io:format("\t =========================="),
    option_menu().


option_menu() ->
    io:format("\n
        [0] Exit \n
        [1] Zwieksz potrzebne oswietlenie +50 lx\n
        [2] Zmniejsz potrzebne oswietlenie -50 lx\n
        [3] zepsuj/napraw czujniki\n
        [4] Set lamp start time\n
        [5] Set lamp stop time\n
        [7] minimalne oswietlenie/ brak \n
        [8] Zapotrzebowanie na oswietlenie nocne \n
        [9] Zapotrzebowanie na oswietlenie delikatne\n
        [10] Zapotrzebowanie na oswietlenie do pracy przy komputerze \n
        [11] Zapotrzebowanie na oswietlenie do pracy szczegolowej\n
        [12] Zapotrzebowanie na pelne oswietlenie\n

Select: ").


add_space_after(Value) ->
    if
        Value =:= on ->
            lists:concat([Value, " "]);

        true -> 
            Value
    end.


time_string({H,M}) ->
    if 
        H > 9 andalso M > 9 ->
            integer_to_list(H) ++ ":" ++ integer_to_list(M);
        M > 9  andalso H < 10 -> 
            "0" ++ integer_to_list(H) ++ ":" ++ integer_to_list(M);
        H > 9 andalso M < 10 ->
            integer_to_list(H) ++ ":0" ++ integer_to_list(M);
        H < 10 andalso M < 10 ->
            "0" ++ integer_to_list(H) ++ ":0" ++ integer_to_list(M)
    end.


time_hm() ->
    {_,Time} = erlang:localtime(),
    {H,M,_} = Time,
    if 
        H > 9 andalso M > 9 ->
            io:format("\t||          ~p:~p         ||\n", [H,M]);
        M > 9  andalso H < 10 -> 
            io:format("\t||          0~p:~p         ||\n", [H,M]);
        H > 9 andalso M < 10 ->
            io:format("\t||          ~p:0~p         ||\n", [H,M]);
        H < 10 andalso M < 10 ->
            io:format("\t||          0~p:0~p         ||\n", [H,M])
    end.

