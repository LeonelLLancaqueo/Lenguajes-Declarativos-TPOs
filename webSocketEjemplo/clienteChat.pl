:- use_module(library(http/websocket)).
:- use_module(library(http/json)).
:- use_module(library(http/http_open)).

iniciar_bot :-
    http_open_websocket(
        'ws://localhost:8080/ws',
        WS,
        []
    ),
    loop_bot(WS).

    loop_bot(WS) :-
    ws_receive(WS, Msg, []),

    ( Msg.opcode == text ->
        atom_json_dict(Msg.data, Dict, []),
        procesar_mensaje(WS, Dict)
    ; true
    ),

    loop_bot(WS).

    procesar_mensaje(WS, Dict) :-
    Dict.tipo == turno,
    decidir_jugada(Dict, Accion),

    atom_json_dict(JSON, Accion, []),

    ws_send(
        WS,
        text(JSON)
    ).

procesar_mensaje(_, _).