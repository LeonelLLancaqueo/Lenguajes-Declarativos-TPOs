:- module(servidorjuego, [main/0]).

:- use_module(library(http/websocket)).
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(lists), [member/2]).





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

% defino puntos del truco
% los puntos son por el nivel de la jerarquia... 
puntos_truco(1-espada, 14).
puntos_truco(1-basto, 13).
puntos_truco(7-espada, 12).
puntos_truco(7-oro, 11).
puntos_truco(3-_, 10).
puntos_truco(2-_, 9).
puntos_truco(1-copa, 8).
puntos_truco(1-oro, 8).
puntos_truco(12-_, 7).
puntos_truco(11-_, 6).
puntos_truco(10-_, 5).
puntos_truco(7-copa, 4).
puntos_truco(7-basto, 4).
puntos_truco(6-_, 3).
puntos_truco(5-_, 2).
puntos_truco(4-_, 1).

%---------------------------------------------
%           INICIO DEL JUEGO
%--------------------------------------------

%defino los estados que atraviersa el juego como una gramatica los cuales pueden ser consumidor y transformados


:- dynamic(mazo/1).

reiniciar:-
% este predicado genera el mazo de cartas creando un conjunto de las cartas posibles y lo denomina "maso" 
	setof(Carta, carta(Carta), Cartas),
    assertz(mazo(Cartas)).

mezclar_cartas :-
	mazo(Cartas),
	mezclar(Cartas, Cartas_mezcladas),
    retractall(mazo(Cartas)),
	assertz(mazo(Cartas_mezcladas)).
    
/*
    (   jugadores(Lista) ->
        retract(jugadores(Lista))
    ;   Lista = []
    ),
    NuevaLista = [jugador(Nombre,[],[] ,WebSocket)|Lista],
    assertz(jugadores(NuevaLista)),
    length(NuevaLista, Cant),
    format("Jugador ~w conectado. Total: ~w~n", [Nombre, Cant]) */

mezclar([], []).
mezclar(Xs0, [Y|Ys]) :-
    length(Xs0, N),
    N1 is N - 1,
    random_between(0, N1, R),
    nth0(R, Xs0, Y, Xs),
    mezclar(Xs, Ys).

%--------------------------------------
%           SERVER
%-----------------------------------
:- dynamic(jugadores/1).
:- dynamic(juego/1).
:- dynamic(mazo/1).

main :-
    http_server(http_dispatch, [port(8316)]),
    format('Servidor truco escuchando en puerto 8316...~n', []),
    esperar_fin_juego.


esperar_fin_juego :-
    (   juego(terminado) ->
        format("Servidor terminando...~n", []),
        halt
    ;   
        esperar_fin_juego
    ).

:- http_handler(root(truco), http_upgrade_to_websocket(procesar_jugador, []), [spawn([])]).

procesar_jugador(WebSocket) :-
    ws_receive(WebSocket, Message, [format(prolog)]),
    format("Recibido: ~w~n", [Message]),
    (   Message.data = join(Nombre) ->
        agregar_jugador(Nombre, WebSocket),
        verificar_inicio
    ;   ws_send(WebSocket, text("Envía join(tu_nombre)"))
    ),
    mantener_activo.

agregar_jugador(Nombre, WebSocket) :-
    (   jugadores(Lista) ->
        retract(jugadores(Lista))
    ;   Lista = []
    ),
    NuevaLista = [jugador(Nombre,[],[] ,WebSocket)|Lista],
    assertz(jugadores(NuevaLista)),
    length(NuevaLista, Cant),
    format("Jugador ~w conectado. Total: ~w~n", [Nombre, Cant]).

verificar_inicio :-
    jugadores(Lista),
    length(Lista, 2), % Solo 2 jugadores para prueba
    !,
    assertz(juego(iniciado)),
    format("Iniciando juego con ~w jugadores~n", [2]),
    iniciar_rondas(Lista).

verificar_inicio :-
    jugadores(Lista),
    forall(member(jugador(_, WS), Lista), 
           ws_send(WS, text("Esperando más jugadores..."))).

mantener_activo :-
    (   juego(terminado) ->
        format("Hilo terminando para websocket~n", [])
    ;   
	mantener_activo
    ).
    
iniciar_rondas(Jugadores) :-
    forall(member(jugador(_, WS), Jugadores),
           ws_send(WS, text("¡Juego iniciado!"))),
    jugar_rondas(Jugadores, 1, 2). % 2 rondas

jugar_rondas(Jugadores, Ronda, MaxRondas) :-
    Ronda > MaxRondas,
    !,
    format("Juego terminado~n", []),
    % Notificar a todos los jugadores y cerrar conexiones
    forall(member(jugador(_, WS), Jugadores),
           ws_send(WS, text("¡Juego terminado!"))
            ),
    assertz(juego(terminado)).
    

jugar_rondas(Jugadores, Ronda, MaxRondas) :-
    format("=== Ronda ~w ===~n", [Ronda]),
    forall(member(jugador(_, WS), Jugadores),
           (atom_concat('Ronda ', Ronda, MsgRonda),
            ws_send(WS, text(MsgRonda)))),
    procesar_turnos(Jugadores, Ronda),
    SigRonda is Ronda + 1,
    jugar_rondas(Jugadores, SigRonda, MaxRondas).

procesar_turnos([], Ronda):-
    format("Todos los jugadores han jugado en ronda ~w~n", [Ronda]).

procesar_turnos([jugador(Nombre, WS)|Resto], Ronda) :-
    format("Turno de ~w en ronda ~w~n", [Nombre, Ronda]),
    
    % Notificar a todos
    jugadores(TodosJugadores),
    atom_concat('Turno de ', Nombre, MsgTurno),
    forall(member(jugador(_, WSAll), TodosJugadores),
           ws_send(WSAll, text(MsgTurno))),
    % Pedir jugada al jugador actual con múltiples intentos
    ws_send(WS, text("tu_turno")),
    ws_send(WS, prolog([opcion1, opcion2, opcion3])),
    
    % Recibir respuesta con timeout más corto y reintentos
    ws_receive(WS, Respuesta, [format(prolog)]),
    format("~w jugó: ~w~n", [Nombre, Respuesta.data]),
    
    % Notificar la jugada a todos con manejo de errores
    format(atom(MsgJugada), '~w eligió ~w', [Nombre, Respuesta.data]),
    forall(member(jugador(_, WSAll), TodosJugadores),
	   catch(ws_send(WSAll, text(MsgJugada)), _, true)),

    procesar_turnos(Resto, Ronda).


