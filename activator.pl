:- module(activator, []).

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module(library(thread)).


:- dynamic(ljtraf/3).
:- dynamic(loc_mom_t/1).
:- dynamic(exam_and_patch_bypass/2).
:- dynamic(antrean_patch_ram/3).

max_requests_allowed(20).
time_window_seconds(2).



htg(IP, 'FORCE_BLOCKED', _PayloadMentah, _Wave) :-
    module:ram_get(IP, 'FORCE_BLOCKED'), !.

htg(IP, VTraf, PayloadMentah, Wave) :-
    max_requests_allowed(Max),
    time_window_seconds(Window),

    module:rate_limit(IP, Max, Window, StatusCode),

    (   StatusCode == 1
    ->
        ( current_predicate(pelajari_dan_kunci_serangan/2)
        ->  catch(pelajari_dan_kunci_serangan(IP, PayloadMentah), _, true)
        ;   true
        ),

        format(user_error, ' KERNEL INTERCEPT IP: ~w detected as malicious! Global wave density: ~w RPS.~n', [IP, Wave]),
        VTraf = 'FORCE_BLOCKED'
    ;   VTraf = 'SAFE_UNDER_THRESHOLD'
    ).

pelajari_dan_kunci_serangan(_IP, PayloadMentah) :-
    format(string(PayloadStr), "~w", [PayloadMentah]),
    string_lower(PayloadStr, PayloadLower),

    (   string_length(PayloadLower, Len), Len > 4
    ->  sub_string(PayloadLower, 0, 4, _, NGram)
    ;   NGram = PayloadLower
    ),

    get_time(TStamp),
    Timestamp is floor(TStamp),

    assertz(module:new_knowledge_base(cyber_defense, PayloadMentah, NGram, 'ABSOLUTE VERIFIED', Timestamp)),
    assertz(antrean_patch_ram(PayloadMentah, NGram, Timestamp)),

    format(user_error, '  IMMUNE RAM, String n-gram: ~q~n', [NGram]),
    !.


deteksi_pelanggaran_kebijakan(PLT, Endpoint, IdAturan) :-
    (   ( sub_atom(PLT, _, _, _, 'STEALTH_SCAN') )
    ->  IdAturan = 'INFRA-STEALTH-01'
    ;   ( sub_atom(PLT, _, _, _, 'SLOWLORIS_CUMULATIVE') ; sub_atom(PLT, _, _, _, 'SLOWLORIS_IDLE') )
    ->  IdAturan = 'INFRA-SLOWLORIS-01'
    ;
        ( sub_atom(PLT, _, _, _, 'SLOW_READ') )
    ->  IdAturan = 'INFRA-SLOWREAD-01'
    ;   sub_atom(Endpoint, _, _, _, 'win.ini')
    ->  IdAturan = 'INFRA-TRAVERSAL-01'
    ;   fail
    ).

proses_policy_breach(UALower, PortFinal, Method, Endpoint, Weight, Velocity, IP, PLT, Wave, VEnd) :-
    (   htg(IP, STraf, PLT, Wave),
        STraf == 'FORCE_BLOCKED'
    ->  VEnd = 'BLOCKED: Volumetric DDoS Detected',
        PayloadMarker = 'POLICY_BREACH_MARKER:HTTP_FLOOD_WAVE: Volumetric attack threshold breached.',
        module:ecl(UALower, PortFinal, Method, Endpoint, Weight, Velocity, IP, PayloadMarker, Wave, VEnd),
        eksekusi_blokir_kernel(IP)

    ;   (   string(PLT), sub_string(PLT, _, _, After, "POLICY_BREACH_MARKER:")
        ->  sub_string(PLT, _, After, 0, StringMurni),
            atom_string(PLTMurni, StringMurni)
        ;   ( atom(PLT) -> PLTMurni = PLT ; atom_string(PLTMurni, PLT) )
        ),

        (   deteksi_pelanggaran_kebijakan(PLTMurni, Endpoint, IdAturan)
        ->  (   current_predicate(protocol_policy:policy_rules/9),
                module:policy_rules(_, IdAturan, _CWE, _Risiko, _Mitigasi, _, _, _, DescTeknis)
            ->  format(atom(VEnd), 'BLOCKED: Infrastructure Threat Mitigated. ~w [~w].', [DescTeknis, IdAturan])
            ;   format(atom(VEnd), 'BLOCKED: Critical Protocol Isolation Breach. [~w] Risk: HIGH. Action: DROP_PACKET.', [IdAturan])
            )
        ;   VEnd = 'BLOCKED: Critical Protocol Isolation Breach. [CWE-699] Risk: HIGH. Action: DROP_PACKET.'
        ),

        format(atom(PayloadDenganPenanda), 'POLICY_BREACH_MARKER:~w', [PLTMurni]),
        module:ecl(UALower, PortFinal, Method, Endpoint, Weight, Velocity, IP, PayloadDenganPenanda, Wave, VEnd),
        eksekusi_blokir_kernel(IP)
    ),
    !.

mikir(UALower, PortFinal, Method, Endpoint, Weight, Velocity, IP, PLT, Wave, VEnd) :-
    atom_string(PLT, StrI),
    (   module:periksa_waf(StrI, Keputusan, Alasan),
        Keputusan == blokir
    ->  format(string(VEnd), "BLOCKED: Malicious Detected (~w)", [Alasan]),
        module:ecl(UALower, PortFinal, Method, Endpoint, Weight, Velocity, IP, PLT, Wave, VEnd)
    ;   string_lower(StrI, IL),
        (   (sub_string(IL, _, _, _, "ddos") ; sub_string(IL, _, _, _, "flood"))
        ->  VEnd = 'BLOCKED: Early Stage Volumetric Detected',
            module:ecl(UALower, PortFinal, Method, Endpoint, Weight, Velocity, IP, PLT, Wave, VEnd)
        ;   VEnd = 'PASSED: Traffic is Clean'
        )
    ),
    !.


exam_and_patch_bypass(_IP, PayloadBypass) :-
    format(string(PayloadStr), "~w", [PayloadBypass]),
    string_lower(PayloadStr, PayloadLower),

    (   string_length(PayloadLower, Len), Len > 4
    ->  sub_string(PayloadLower, 0, 4, _, NGram)
    ;   NGram = PayloadLower
    ),

    get_time(TStamp),
    Timestamp is floor(TStamp),

    assertz(module:new_knowledge_base(cyber_defense, PayloadBypass, NGram, 'ABSOLUTE VERIFIED', Timestamp)),
    assertz(antrean_patch_ram(PayloadBypass, NGram, Timestamp)),

    format(user_error, ' IMMUNE SYSTEM SELF-HEALED New bypass pattern locked permanently: ~q~n', [NGram]),
    !.


inisialisasi_background_logger :-
    catch(
        thread_create(loop_flush_patch_ke_disk, _, [detached(true), alias(aethel_disk_worker)]),
        _,
        true
    ).

loop_flush_patch_ke_disk :-
    sleep(60),
    findall(data(P, N, T), retract(antrean_patch_ram(P, N, T)), DaftarAntrean),
    (   DaftarAntrean \== []
    ->  FilePathPatch = 'patch_rules.pl',
        catch(
            setup_call_cleanup(
                open(FilePathPatch, append, Stream, [encoding(utf8), buffer(false)]),
                forall(member(data(Payload, NGram, Timestamp), DaftarAntrean),
                    format(Stream, "new_knowledge_base(cyber_defense, ~q, ~q, 'ABSOLUTE VERIFIED', ~w).~n",
                           [Payload, NGram, Timestamp])
                ),
                close(Stream)
            ),
            ErrorIO,
            format(user_error, ' I/O ERROR BACKGROUND Failed : ~w~n', [ErrorIO])
        ),
        length(DaftarAntrean, TotalAturan),
        format(user_error, '  DISK PERSISTENCE write ~w new rules~n', [TotalAturan])
    ;   true
    ),
    loop_flush_patch_ke_disk.

validasi_ip_dcg --> validasi_ip_v4_dcg.
validasi_ip_dcg --> validasi_ip_v6_dcg.


validasi_ip_v4_dcg --> oktet, ".", oktet, ".", oktet, ".", oktet.

oktet --> [C1, C2, C3], { digit(C1), digit(C2), digit(C3), kodes_ke_angka([C1,C2,C3], N), N >= 0, N =< 255 }, !.
oktet --> [C1, C2],     { digit(C1), digit(C2), kodes_ke_angka([C1,C2], N), N >= 0, N =< 255 }, !.
oktet --> [C1],         { digit(C1) }.

validasi_ip_v6_dcg --> blok_heksa, ":", kelanjutan_v6(1).
validasi_ip_v6_dcg --> "::", kelanjutan_kompresi(0).

kelanjutan_v6(7) --> blok_heksa, !.
kelanjutan_v6(Count) --> blok_heksa, ":", { CountBaru is Count + 1 }, kelanjutan_v6(CountBaru), !.
kelanjutan_v6(Count) --> ":", { Count =< 6 }, kelanjutan_kompresi(Count), !.

kelanjutan_kompresi(7) --> [].
kelanjutan_kompresi(Count) --> blok_heksa, { CountBaru is Count + 1 }, sisa_blok_kompresi(CountBaru).
kelanjutan_kompresi(_) --> [].

sisa_blok_kompresi(8) --> [].
sisa_blok_kompresi(Count) --> ":", blok_heksa, { CountBaru is Count + 1 }, sisa_blok_kompresi(CountBaru).
sisa_blok_kompresi(_) --> [].

blok_heksa --> [C1, C2, C3, C4], { heksa(C1), heksa(C2), heksa(C3), heksa(C4) }, !.
blok_heksa --> [C1, C2, C3],     { heksa(C1), heksa(C2), heksa(C3) }, !.
blok_heksa --> [C1, C2],         { heksa(C1), heksa(C2) }, !.
blok_heksa --> [C1],             { heksa(C1) }.

digit(C) :- C >= 0x30, C =< 0x39. % '0'-'9'

heksa(C) :- C >= 0x30, C =< 0x39. % '0'-'9'
heksa(C) :- C >= 0x61, C =< 0x66. % 'a'-'f'
heksa(C) :- C >= 0x41, C =< 0x46. % 'A'-'F'

kodes_ke_angka(Codes, Angka) :- number_codes(Angka, Codes).

eksekusi_blokir_kernel(IP) :-
    atom_codes(IP, KodeKarakter),

    (   \+ phrase(validasi_ip_dcg, KodeKarakter)
    ->  format(user_error, ' [SECURITY ALERT] Percobaan Shell Injection digagalkan via DCG! IP Ilegal: ~w~n', [IP]), !, fail
    ;   true
    ),

    (   member(0x3A, KodeKarakter)
    ->  TipeProtokol = [IP]
    ;   TipeProtokol = [IP]
    ),

    (   current_prolog_flag(windows, true)
    ->  OSName = 'WINDOWS KERNEL INTERCEPTOR',
        format(atom(FullCmd), [WINDOWS_FIREWALL_COMMAND], [IP, IP])
    ;   OSName = 'LINUX KERNEL NETFILTER',
        (   TipeProtokol == ipv6
        ->  % Gunakan set ipset ber-family inet6 untuk menampung alamat IPv6
            format(atom(FullCmd), [LINUX_IPSET_COMMAND], [IP])
        ;   % Default IPv4
            format(atom(FullCmd), [LINUX_IPSET_COMMAND], [IP])
        )
    ),

    catch(
        (   shell(FullCmd, StatusKeluaran),
            (   StatusKeluaran == 0
            ->  format(user_error, ' [~w] IP ~w (~w) Resmi Dikunci Mati di Level Silikon Kernel!~n', [OSName, IP, TipeProtokol])
            ;   format(user_error, ' [~w] Gagal Menyuntikkan Aturan (Status: ~w). Periksa privilese root/admin.~n', [OSName, StatusKeluaran])
            )
        ),
        ErrorOS,
        format(user_error, ' [~w] Kegagalan Eksekusi: ~w~n', [OSName, ErrorOS])
    ),
    !.

