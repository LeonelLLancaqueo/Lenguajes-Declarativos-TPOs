:- module(clientejuego, [main/0]).

:- use_module(library(http/websocket)).

%-----------------------------------
%   DEFINICION DE CARTAS
%---------------------------------
%palo
palo(oro).
palo(copa).
palo(espada).
palo(basto).

% defino las cartas 
numero(12).
numero(11).
numero(10).
numero(7).
numero(6).
numero(5).
numero(4).
numero(3).
numero(2).
numero(1).

%defino carta numero y palo
carta(S-N):-
    numero(S),
    palo(N).

main :-
    format("Ingresa tu nombre: "),
    read(Nombre),
    format("Conectando a ws://localhost:8316/truco~n", []),
    http_open_websocket('ws://localhost:8316/truco', WebSocket, []),
    ws_send(WebSocket, prolog(join(Nombre))),
    escuchar_mensajes(WebSocket).

escuchar_mensajes(Stream) :-
    format("Esperando mensajes...~n", []),
    ws_receive(Stream, Message, []),
    procesar_mensaje(Stream, Message).

procesar_mensaje(Stream, Message) :-
    (   Message.data == "tu_turno" ->
        manejar_turno(Stream)
    ;   Message.data == "¡Juego terminado!" ->
        format("~w~n", [Message.data]),
        format("Desconectando...~n", []),
        ws_close(Stream, 1000, "Cliente terminando")
    ;   Message.opcode == close ->
        format("Conexión cerrada por el servidor~n", [])
    ;   
        format("Mensaje: ~w~n", [Message]),
        escuchar_mensajes(Stream)
    ).

manejar_turno(Stream) :-
    format("¡Es tu turno!~n", []),
    ws_receive(Stream, Opciones, [format(prolog)]),
    format("Mensaje: ~w~n", [Opciones]),
    Opciones.data = cartas(Cartas),
    format("Opciones disponibles: ~w~n", [Cartas]),
    format("Elige una opción: "),
    read(CartaJugada),
    ws_send(Stream, prolog(carta(CartaJugada))),
    format("Jugada enviada: ~p~n", [CartaJugada]),
    escuchar_mensajes(Stream).
