:- module(activator, [ mikir/3 ]). 

:- use_module(dataset_cyber_security). 
:- use_module(decoder).

:- dynamic ljtraf/3. 
:- dynamic loc_mom_t/1. 

max_requests_allowed(60).
time_window_seconds(3).

htg(IP, VTraf) :- 
    get_time(Wkt), 
    max_requests_allowed(Max), 
    time_window_seconds(Window), 
    ( retract(ljtraf(IP, HitOld, WktOld)) -> 
        ( Wkt - WktOld =< Window -> 
            HitNew is HitOld + 1, 
            WktNew = WktOld 
        ; 
            HitNew = 1, 
            WktNew = Wkt 
        ) 
    ; 
        HitNew = 1, 
        WktNew = Wkt 
    ), 
    assertz(ljtraf(IP, HitNew, WktNew)), 
    ( HitNew > Max -> 
        ( loc_mom_t(IP) -> 
            VTraf = 'FORCE_BLOCKED' 
        ; 
            assertz(loc_mom_t(IP)), 
            VTraf = 'FORCE_BLOCKED' 
        ) 
    ; 
        VTraf = 'SAFE_UNDER_THRESHOLD' 
    ).

mikir(IP, PLT, VEnd) :- 
    htg(IP, STraf), 
    ( STraf == 'FORCE_BLOCKED' -> 
        VEnd = ' BLOCKED: Volumetric DDoS Detected' 
    ; 
        pld(PLT, Inpt), 
        
        (   cdb(Inpt, PMut, Desc)
        ->  format(string(VEnd), " BLOCKED: Malicious Payload Detected -> Signature: ~w (~w)", [PMut, Desc])
        ;   VEnd = ' PASSED: Traffic is Clean'
        ) 
    ), 
    !. 

cdb(Inpt, PMut, Desc) :-
    dataset_cyber_security:knowledge_base(cyber_defense, PMut, V, Desc),
    format(string(V_Str), "~w", [V]),
    V_Str == "ABSOLUTE VERIFIED",
    format(string(P_Raw), "~w", [PMut]),
    string_lower(P_Raw, P), 
    sub_string(Inpt, _, _, _, P).
