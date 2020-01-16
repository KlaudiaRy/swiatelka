-module(lights).
-export([run/0, main/1, timer/1]).

% Imports
-import(display, [display_window/5]).
-import(extras, [round1dec/1, check_time/2, is_light_avaliable/1, get_time/0]).


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


%tutaj przydzielamy pid do funkcji + argumenty początkowe i włączamy nasłuchiwacza
run() -> 

    P_lamp = spawn(fun lamp/0),
    P_timer = spawn(lights, timer, [{{6,0},{23,0},undefined, P_lamp, on}]),
    P_day = spawn(fun daylight_changer/0),
    P_bright = spawn(fun automatic_lights/0),
    P_main = spawn(lights, main, [{P_lamp,?start_brightness,P_bright,P_day,on,  P_timer, ?minimum_light, ?sensor_damage, ?given_light_prefference, {on, {{6,0},{23,0}}}}]),
    listener({P_main}).

%nasłuchiwacz pobiera komendy po uruchomieniu lights:run().
listener({P_main}) ->
    {Command,_} = string:to_integer(io:get_line("")), %bierze komendę
    if
		Command < 0 ->
			io:format("Podaj liczbe z zakresu od 0 do 14\n\n");
		Command > 14 ->
			io:format("Podaj liczbe z zakresu od 0 do 14\n\n");
		true -> 
			P_main!{control, Command}  %wysyła komendę do main
	end, %wysyła komendę do main
    listener({P_main}). %ponownie nasłuchuje - uruchamia sam siebie


main({P_lamp,Daylight,P_bright,P_day,Up_down,P_timer, Automatic_light, Sens_damage, Wanted, Stat}) -> %przybiera wszystkie zmienialne dane
    io:format(os:cmd(clear)),
    io:format("\n----===== Inteligentne Oswietlenie =====---- \n\n"),
    
%czy czujniki sa zepsute - odpowiednia informacja
    if
        Sens_damage =:= 0 ->
            Sens_status = "Aktywne ";
        true ->
            Sens_status = "Nieaktywne"
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
    %rysowanie okna
    display_window(Daylight, Automatic_light, Wanted, Sens_status, Stat),
    receive
        %zmiana wartosci automatycznego oswietlenia
        {data, up, Value} ->
            Updated_light = Automatic_light + Value,
            main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Updated_light, Sens_damage, Wanted, Stat });

        {data, down, Value} ->
            Updated_light = Automatic_light - Value,
            main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Updated_light, Sens_damage, Wanted, Stat });

        {lamp, Stat_New} -> %otrzymany automatyczny stan lamp
            main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, Wanted, Stat_New });
        
         %manualne stany lamp
        {lamp, Stat_New,on} -> 
            main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, Wanted, Stat_New });
        {lamp, Stat_New,off} ->
            main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, 0, Sens_damage, 0, Stat_New });
        
    
        {brightness, Perfect_val} -> %otrzymana dobrana wartosc swiatla sztucznego
            main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Perfect_val, Sens_damage, Wanted, Stat });
        
        {daylights, Val} -> %zmiana swiatla naturalnego
            main({P_lamp,Val,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, Wanted, Stat });

        {control, 0} -> %Wyjscie z programu - > exit
            init:stop(0);

          {control, 1} -> %zwiekszenie preferowanego oswietlenia
            Given_plus = Wanted + 50,
            Given_checked = is_light_avaliable(Given_plus),
            main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, Given_checked, Stat });

        {control, 2} -> %zmniejszenie preferowanego oswietlenia
            Given_minus = Wanted - 50,
            Given_checked = is_light_avaliable(Given_minus),
            main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, Given_checked, Stat });
        
        {control, 3} -> %zepsucie czujnika
                    if 
                        Sens_damage =:= 1 ->
                            main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, 0, Wanted, Stat });
                        true -> 
                            main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, 1, Wanted, Stat })
                    end;

        {control, 4} -> %Ustawienie czasu włączenia lamp
                    {H, M} = get_time(),
                    P_timer ! {time_to_start,H,M, self()},
                    main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, Wanted, Stat });

        {control, 5} -> %Ustawienie czasu wylaczenia lamp
                    {H, M} = get_time(),
                    P_timer ! {time_to_stop,H,M, self()},
                    main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, Wanted, Stat });

        {control, 6} -> %wylacz lampy
                    P_lamp!{offf,self(),Stat},
                    main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, 0, Sens_damage, ?minimum_light, Stat });
        {control, 13} -> %wlacz lampy
                    P_lamp!{onn,self(),Stat},
                    main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, ?given_light_prefference, Stat });

        {control, 7} -> %minimalne oswietlenie/ brak
                    main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, ?minimum_light, Stat });

        {control, 8} -> %Zapotrzebowanie na oswietlenie nocne
                    main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, ?night_light, Stat });

        {control, 9} -> %Zapotrzebowanie na oswietlenie delikatne

                    main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, ?soft_light, Stat });

        {control, 10} -> %Zapotrzebowanie na oswietlenie do pracy przy komputerze

                    main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, ?computer_work_light, Stat });

        {control, 11} -> %Zapotrzebowanie na oswietlenie do pracy szczegolowej

                    main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, ?work_light, Stat });

        {control, 12} -> %Zapotrzebowanie na pelne oswietlenie

                    main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, ?maximum_light, Stat });
        {control, 14} -> %Wroc do trybu automatycznego zarzadzania stanem lamp
                    P_lamp!{on_aut,self(),Stat},
                    main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, ?maximum_light, Stat });

        _ ->
            main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, Wanted, Stat })
        
    %po sekundzie:
    after 1000 -> 
        if
            %o ile działa czujnik:
            Sens_damage =:= 0 ->
                P_bright!{onn,self(),Daylight,Wanted},
            
                P_day!{Up_down,self(),Daylight},

                main({P_lamp,Daylight,P_bright,P_day,Up_down_n,P_timer, Automatic_light, Sens_damage, Wanted, Stat });
                
            true ->
                main({P_lamp,0,P_bright,P_day,Up_down_n,P_timer, Wanted, Sens_damage, Wanted, Stat })
        end
    end.


%zmienia natezenie lamp w zaleznosci od natezenia swiatla dziennego
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


% Decyzje o stanie wlaczenia lamp
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

% Stan wlaczenia lamp
lamp() ->
    receive
        {_, undefined, _} ->
            lamp();
        {on, P_main, Times} ->
            P_main!{lamp, {on, Times},on},
            lamp();
        {off, P_main, Times} ->
            P_main!{lamp, {off,Times},off},
            lamp();
        {onn,P_main,{_, {{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}}}->
            P_main!{lamp, {m_on, {{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}}},
            lamp();
        {on_aut,P_main,{_, {{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}}}->
            P_main!{lamp, {on, {{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}}},
            lamp();
        {offf,P_main,{_, {{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}}}->
            P_main!{lamp, {m_off, {{Given_start_H, Given_start_M},{Given_stop_H, Given_stop_M}}}},
            lamp()
    end.
