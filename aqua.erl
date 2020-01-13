-module(aqua).
-export([run/0, main/1, timer/1]).

% Imports
-import(display, [draw_panel/5]).
-import(helper, [round1dec/1, check_time/2, is_light_avaliable/1, get_time/0]).


% % Dedfines 
-define(sensor_damage, 0).
-define(given_light_prefference, 1000).
-define(night_light,20).
-define(soft_light,50).
-define(minimum_light,0).
-define(computer_work_light,500).
-define(work_light,1000).
-define(maximum_light,5000).
-define(start_brightness,4100).


% Runing function
%tutaj przydzielamy pid do funkcji + argumenty początkowe i włączamy nasłuchiwacza
run() -> 
    P_tmp_sens = spawn(fun tmp_sens/0),
    P_heater = spawn(fun heater/0),
    P_lamp = spawn(fun lamp/0),
    P_timer = spawn(aqua, timer, [{{0,0},{0,0},undefined, P_lamp, off}]),
    P_day = spawn(fun daylight_changer/0),
    P_bright = spawn(fun automatic_lights/0),
    P_main = spawn(aqua, main, [{?start_brightness,P_bright,P_day,on,P_tmp_sens, P_heater, P_timer, ?minimum_light, ?sensor_damage, ?given_light_prefference, {off, {{0,0},{0,0}}}}]),
    control_listener({P_tmp_sens, P_heater, P_main}).

% Waiting for interrup 
%nasłuchiwacz pobiera komendy po uruchomieniu aqua:run().
control_listener({P_tmp_sens, P_heater, P_main}) ->
    {Functionality,_} = string:to_integer(io:get_line("")), %bieże komendę
    P_main!{control, Functionality},  %wysyła komendę do main
    control_listener({P_tmp_sens, P_heater, P_main}). %ponownie nasłuchuje - uruchamia sam siebie


main({Daylight,P_bright,P_day,Up_down,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat}) -> %przybiera wszystkie zmienialne dane
    io:format(os:cmd(clear)),
    io:format("----===== Aquarium Control Manager =====---- \n\n"),
    
    if
        Sens_damage =:= 0 ->
            Sens_status = "No ";

        true ->
            Sens_status = "Yes"
    end,

%osiągnięto górną granicę jasności - południe, zaczyna się ściemniać i odwrotnie
    if 
        Daylight > 4900 ->
            Up_down_n='off';
        Daylight <50 ->
            Up_down_n ='on';
        true ->
            Up_down_n = Up_down
    end,

    draw_panel(Daylight, Actual_temp, Given, Sens_status, Stat),
    receive
        {data, up, Value} ->
            Updated_temp = Actual_temp + Value,
            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Updated_temp, Sens_damage, Given, Stat });

        {data, down, Value} ->
            Updated_temp = Actual_temp - Value,
            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Updated_temp, Sens_damage, Given, Stat });

        {lamp, Albert} ->
            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Albert });
        {brightness, Perfect_val} ->
            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Perfect_val, Sens_damage, Given, Stat });
        
        {daylights, Val} ->
            main({Val,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat });

        {control, 0} -> %Exit
            init:stop(0);

          {control, 1} -> %Given light UP
            Given_plus_one = Given + 50,
            Given_checked = is_light_avaliable(Given_plus_one),
            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given_checked, Stat });

        {control, 2} -> %Given temp DOWN
            Given_subs_one = Given - 50,
            Given_checked = is_light_avaliable(Given_subs_one),
            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given_checked, Stat });
        
        {control, 3} -> %sensor error
            if 
                Sens_damage =:= 1 ->
                    % Turn off sensor errror
                    main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, 0, Given, Stat });
                true -> 
                    %  Turn on sensor errror
                    main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, 1, Given, Stat })
            end;

        {control, 4} -> %Set lamp start time
            {H, M} = get_time(),
            P_timer ! {time_to_start,H,M, self()},
            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat });

        {control, 5} -> %Set lamp stop time
            {H, M} = get_time(),
            P_timer ! {time_to_stop,H,M, self()},
            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat });

        {control, 7} -> %minimalne oswietlenie/ brak
            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, ?minimum_light, Stat });

{control, 8} -> %Zapotrzebowanie na oswietlenie nocne
            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, ?night_light, Stat });

{control, 9} -> %Zapotrzebowanie na oswietlenie delikatne

            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, ?soft_light, Stat });

{control, 10} -> %Zapotrzebowanie na oswietlenie do pracy przy komputerze

            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, ?computer_work_light, Stat });

{control, 11} -> %Zapotrzebowanie na oswietlenie do pracy szczegolowej

            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, ?work_light, Stat });

{control, 12} -> %Zapotrzebowanie na pelne oswietlenie

            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, ?maximum_light, Stat });

        _ ->
            main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat })
        

    after 1000 -> 
        if
            Sens_damage =:= 0 ->
                P_bright!{onn,self(),Daylight,Given},
                P_tmp_sens!{P_heater,self(), Actual_temp, Given},

              
                P_day!{Up_down,self(),Daylight},

                main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat });
                
            true ->
                main({Daylight,P_bright,P_day,Up_down_n,P_tmp_sens, P_heater, P_timer, Actual_temp, Sens_damage, Given, Stat })
        end
    end.
  
% Temp Sensor process main function //ZMIENIONE DZIALANIE
tmp_sens() ->
    receive
        {P_heater,P_main,Actual_temp, Given} ->
            % if  Value < Zadana -> ON to heater
            % else -> OFF to heater
            if
                Actual_temp  < Given ->
                    P_heater!{self(),P_main,on},
                    tmp_sens();

                true ->
                    P_heater!{self(),P_main,off},
                    tmp_sens()
            end                   
    end.

% Heater process main function //ZMIENIONE DZIALANIE
heater() ->
    receive
        {_,P_main,on} ->
            % Wait 1 sec, and send rand value (0.1 - 3) to core
            timer:sleep(1000),
            Rand_val = rand:uniform(50),
            P_main!{data, up, Rand_val},
            heater();

        {_,P_main,off} ->
            % Wait 1 sec, and send rand value (0.1 - 3)
            timer:sleep(1000),
            Rand_val = rand:uniform(50),
            P_main!{data, down, Rand_val},
            heater()
    end.


%zmienia natezenie lamp w zaleznosci od natezenia swiatla dzinnego
automatic_lights() ->
    receive
        {onn,P_main,Daylight,Given} ->
            Perfect_val = Given-Daylight,
            if Perfect_val<0 ->
                Val = 0;
            true ->
                Val = Perfect_val
            end,
            P_main!{brightness, Val},
            automatic_lights()
    end.




% samoistna zmiana światła naturalnego (zewnętrznego)
daylight_changer() ->
    Val = rand:uniform(100),
    receive
        {_, undefined, _} ->
            daylight_changer();
        {on, P_main,Daylight} ->
            Daylight_n=Daylight+Val,
            P_main!{daylights, Daylight_n},
            daylight_changer();
        {off, P_main,Daylight} ->
            Daylight_n=Daylight-Val,
            P_main!{daylights, Daylight_n},
            daylight_changer()
    end.




% Timer process main function
timer({{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M},P_main, P_lamp, State}) ->
    A = check_time({Given_start_H * 60 + Given_start_M},{Given_stop_H * 60 + Given_stop_M}),
    if
        A andalso State =:= off ->
            P_lamp ! {on,P_main,{{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}};

        A =:= false andalso State =:= on -> 
            P_lamp ! {off, P_main,{{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}};

        true -> ok
    end,
    receive
        {time_to_start,H1,M1, P_main_new} ->
            P_lamp ! {State,P_main_new,{{H1, M1},{Given_stop_H, Given_stop_M}}},
            timer({{H1,M1},{Given_stop_H, Given_stop_M}, P_main_new, P_lamp, State});

        {time_to_stop,H1,M1, P_main_new} ->
            P_lamp ! {State,P_main_new,{{Given_start_H, Given_start_M},{H1, M1}}},
            timer({{Given_start_H, Given_start_M},{H1,M1}, P_main_new, P_lamp, State})
    after 1000 ->
        timer({{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M},P_main,P_lamp, State})
    end.

% Lamp process main function
lamp() ->
    receive
        {_, undefined, _} ->
            lamp();
        {on, P_main, Times} ->
            P_main!{lamp, {on, Times}},
            lamp();
        {off, P_main, Times} ->
            P_main!{lamp, {off,Times}},
            lamp()
    end.
