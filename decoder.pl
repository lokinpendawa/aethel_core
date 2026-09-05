:- module(decoder, [ pld/2 ]).

% ==============================================================================
% DECODER ENGINE UTAMA
% ==============================================================================
pld(RawPayload, CleanString) :-
    atom_string(RawPayload, Str0),
    string_lower(Str0, Str1),
    dekode_url(Str1, Str2),          % Lapisan 1: URL Decoding (%20, %27)
    dekode_hex(Str2, Str3),          % Lapisan 2: Hex Decoding (\x27, 0x27)
    dekode_html(Str3, StrClean),     % Lapisan 3: HTML Entities Decoding (&lt;)
    string_lower(StrClean, CleanString).

% --- Lapisan 1: URL Decoder ---
dekode_url(In, Out) :-
    (   sub_string(In, Before, 3, After, HexPart),
        sub_string(HexPart, 0, 1, _, "%")
    ->  sub_string(HexPart, 1, 2, _, HexChars),
        catch(
            (   string_chars(HexChars, [C1,C2]),
                char_type(C1, xdigit(_)), char_type(C2, xdigit(_)),
                string_concat("0x", HexChars, HexStr),
                atom_string(HexAtom, HexStr),
                atom_number(HexAtom, Code),
                char_code(Char, Code),
                atom_string(Char, ReplStr)
            ),
            _,
            ReplStr = HexPart
        ),
        sub_string(In, 0, Before, _, SubBef),
        sub_string(In, _, After, 0, SubAft),
        string_concat(SubBef, ReplStr, Temp),
        string_concat(Temp, SubAft, Next),
        dekode_url(Next, Out)
    ;   Out = In
    ).

% --- Lapisan 2: Hex/Escape Decoder ---
dekode_hex(In, Out) :-
    (   sub_string(In, Before, 4, After, HexPart),
        ( sub_string(HexPart, 0, 2, _, "\\x") ; sub_string(HexPart, 0, 2, _, "0x") )
    ->  sub_string(HexPart, 2, 2, _, HexChars),
        catch(
            (   string_chars(HexChars, [C1,C2]),
                char_type(C1, xdigit(_)), char_type(C2, xdigit(_)),
                string_concat("0x", HexChars, HexStr),
                atom_string(HexAtom, HexStr),
                atom_number(HexAtom, Code),
                char_code(Char, Code),
                atom_string(Char, ReplStr)
            ),
            _,
            ReplStr = HexPart
        ),
        sub_string(In, 0, Before, _, SubBef),
        sub_string(In, _, After, 0, SubAft),
        string_concat(SubBef, ReplStr, Temp),
        string_concat(Temp, SubAft, Next),
        dekode_hex(Next, Out)
    ;   Out = In
    ).

% --- Lapisan 3: HTML Entities Decoder ---
dekode_html(In, Out) :-
    (   sub_string(In, Before, _, After, "&quot;")
    ->  sub_string(In, 0, Before, _, B), sub_string(In, _, After, 0, A),
        string_concat(B, "\"", T), string_concat(T, A, N), dekode_html(N, Out)
    ;   sub_string(In, Before, _, After, "&lt;")
    ->  sub_string(In, 0, Before, _, B), sub_string(In, _, After, 0, A),
        string_concat(B, "<", T), string_concat(T, A, N), dekode_html(N, Out)
    ;   sub_string(In, Before, _, After, "&gt;")
    ->  sub_string(In, 0, Before, _, B), sub_string(In, _, After, 0, A),
        string_concat(B, ">", T), string_concat(T, A, N), dekode_html(N, Out)
    ;   sub_string(In, Before, _, After, "&#x27;")
    ->  sub_string(In, 0, Before, _, B), sub_string(In, _, After, 0, A),
        string_concat(B, "'", T), string_concat(T, A, N), dekode_html(N, Out)
    ;   Out = In
    ).
