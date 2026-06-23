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

ninguna(1).
truco(2).
retruco(3).
valecutro(4).





% defino predicado para obtener los puntos de una carta de truco.
puntos_carta_truco(X,N):-
    carta(X),
    puntos_truco(X,N).


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



%-----------------------------------------
%   CREACION DE JUGADORES
%--------------------------------------------

:- http_handler(root(truco), http_upgrade_to_websocket(procesar_jugador, []), [spawn([])]).

:- dynamic(jugadores/1).
:- dynamic(juego/1).
:- dynamic(puntosApuesta/1).


procesar_jugador(WebSocket) :-
    format("Cliente WebSocket conectado~n", []),
    ws_receive(WebSocket, Message, []),
    term_string(Term, Message.data),
    format("Recibido: ~w~n", [Message]),
    (   Term = join(Nombre) ->
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
    NuevaLista = [jugador(Nombre,[],[],[] ,WebSocket)|Lista],
    assertz(jugadores(NuevaLista)),
    length(NuevaLista, Cant),
    format("Jugador ~w conectado. Total: ~w~n", [Nombre, Cant]).
%------------------------------------------
%   REPARTO DE CARTAS
%---------------------------------------------
% separo la baraja de cartas de la creacion de jugador para desacoplar el codigo
barajar_rondas :-      
    barajar_a_jugador,
	barajar_a_jugador,
	barajar_a_jugador.

barajar_a_jugador:-
    jugadores(Jugadores),
    mazo(Cartas),
	barajar_a_jugador(Jugadores, NewJugadores, Cartas, NewCartas), % genero el nuevo estado de jugador y baraja
	retractall(jugadores(Jugadores)),
    retractall(mazo(Cartas)),
    assertz(jugadores(NewJugadores)),
    assertz(mazo(NewCartas)),
    format("Jugadores y Cartas: ~w~n", [NewJugadores]).

barajar_a_jugador([], [], CartasOut, CartasOut).
barajar_a_jugador(JugadoresOut, JugadoresOut, [], []).
barajar_a_jugador([JugadorIn|JugadoresIn], [JugadorOut|JugadoresOut], [Carta|Cartas], CartasOut) :-
    JugadorIn = jugador(Nombre, CartasJugador, CartasJugadas,CartaWin, Socket), % jugador estado actual
    JugadorOut = jugador(Nombre, [Carta|CartasJugador], CartasJugadas,CartaWin, Socket), % jugador nuevo estado con una carta mas sacada del mazo.
    barajar_a_jugador(JugadoresIn, JugadoresOut, Cartas, CartasOut).

%--------------------------------------
%           SERVER
%-----------------------------------


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

verificar_inicio :-
    jugadores(Lista),
    length(Lista, 2), % Solo 2 jugadores para prueba
    !,
    assertz(juego(iniciado)),
    format("Iniciando juego con ~w jugadores~n", [2]),
    iniciar_rondas(Lista).
    

verificar_inicio :-
    jugadores(Lista),
    forall(member(jugador(_,_,_,_,WS), Lista), 
           ws_send(WS, text("Esperando mas jugadores..."))).

mantener_activo:-
    (   juego(terminado) ->
        format("Hilo terminando para websocket~n", [])
    ;
    sleep(4),   
	mantener_activo
    ).
    
iniciar_rondas(Jugadores) :-
    reiniciar,
    mezclar_cartas,
    barajar_rondas,
    assertz(puntosApuesta(1)),
    jugadores(JugadoresConCartas),
    assertz(apuesta(ninguna)),
    forall(member(jugador(_,_,_,_,WS), Jugadores),
           ws_send(WS, text("Juego iniciado!"))),
    jugar_rondas(JugadoresConCartas, 1, 3). % 2 rondas.

terminar_juego(Jugadores, NombreGanador) :-
    puntosApuesta(Puntos),
    format(atom(MsgGanador), 'Ganador ~w', [NombreGanador]),
    format(atom(MsgPuntos), 'Puntos ~w', [Puntos]),

    forall(
        member(jugador(_,_,_,_,WS), Jugadores),
        (
            ws_send(WS, text("Juego terminado!")),
            ws_send(WS, text(MsgGanador)),
            ws_send(WS, text(MsgPuntos))
        )
    ),
    assertz(juego(terminado)).

ganador_por_rondas([jugador(N1,_,_,W1,_), jugador(N2,_,_,W2,_)],Ganador) :-
    length(W1, L1),
    length(W2, L2),
    (
        L1 >= L2 -> Ganador = N1
    ;
        Ganador = N2
    ).


jugar_rondas(Jugadores, _Ronda, _MaxRondas) :-
    member(jugador(NombreGanador, _, _, CartasWin, _), Jugadores),
    length(CartasWin, CantWin),
    CantWin >= 2,
    !,
    terminar_juego(Jugadores, NombreGanador).

jugar_rondas(Jugadores, Ronda, MaxRondas) :-
    Ronda > MaxRondas,
    !,
    ganador_por_rondas(Jugadores, NombreGanador),
    terminar_juego(Jugadores, NombreGanador).

jugar_rondas(Jugadores, Ronda, MaxRondas) :-
    format("=== Ronda ~w ===~n", [Ronda]),
    forall(member(jugador(_,_,_,_, WS), Jugadores),
           (atom_concat('Ronda ', Ronda, MsgRonda),
            ws_send(WS, text(MsgRonda)))),
    procesar_turnos(Jugadores, CartasSelec, Ronda),
    format("Jugadores: ~w~n", [Jugadores]),
    format("Cartas seleccionadas: ~w~n", [CartasSelec]),
    ganador_ronda(CartasSelec, WinnerCard),
    format("Mejor carta: ~w~n", [WinnerCard]),
    maplist(quitar_carta, Jugadores, CartasSelec, JugadoresNext),
    format("Jugadores Next: ~w~n", [JugadoresNext]),
    nth0(N, CartasSelec, WinnerCard),
	nth0(N, JugadoresNext, WinnerPlayer0),

    append(PBefore, [WinnerPlayer0|PAfter], JugadoresNext),
	WinnerPlayer0 = jugador(WinnerName, Cartas, CartasJugadas, CartasWin,Socket),
	append(CartasWin,[WinnerCard], CartasWinFinal),
	append([jugador(WinnerName, Cartas, CartasJugadas, CartasWinFinal,Socket)|PAfter], PBefore, JugadoresFinal),


    format("Carta Ganadora es ~w from ~w~n", [WinnerCard, WinnerName]),

    SigRonda is Ronda + 1,
    jugar_rondas(JugadoresFinal, SigRonda, MaxRondas).



quitar_carta(JugadorIn, CartaJugada, JugadorOut) :-
    JugadorIn = jugador(Nombre, Cartas, CartasJugadas, CartasWin, WebSocket),
    select(CartaJugada, Cartas, CartasOut),
    JugadorOut = jugador(Nombre, CartasOut, [CartaJugada|CartasJugadas], CartasWin, WebSocket).

procesar_turnos([],[], Ronda ):-
    format("Todos los jugadores han jugado en ronda ~w~n", [Ronda]).



procesar_turnos([jugador(Nombre, Cartas, _, _, WS)|Resto],
                [CartaSelec|CartasSelec],
                Ronda) :-

    format("Turno de ~w en ronda ~w~n", [Nombre, Ronda]),

    %% jugadores(TodosJugadores),

    broadcast(turno(Nombre, Ronda)),

    enviar(WS, tu_turno),
    enviar(WS, cartas(Cartas)),

    ws_receive(WS, Respuesta, []),
    term_string(Term, Respuesta.data),

    procesar_accion_turno(Term, Nombre, WS, Cartas, CartaSelec),

    CartaSelec \= abandono,

    format("~w jugo: ~w~n", [Nombre, CartaSelec]),

    broadcast(jugada(Nombre, CartaSelec)),

    procesar_turnos(Resto, CartasSelec, Ronda).


procesar_accion_turno(carta(CartaSelec), _Nombre, _WS, Cartas, CartaSelec) :-
    member(CartaSelec, Cartas).

procesar_accion_turno(truco(Canto), Nombre, WS, Cartas, CartaSelec) :-
    retractall(puntosApuesta(_)),
    assertz(puntosApuesta(2)),
    broadcast(apuesta(Nombre, Canto)),
    pedir_respuesta_a_rival(Nombre, Canto, Acepto),
    (
        Acepto = si
    ->
        enviar(WS, jugar_carta),
        ws_receive(WS, MsgCarta, []),
        term_string(carta(CartaSelec), MsgCarta.data),
        member(CartaSelec, Cartas)

    ;
        Acepto = no
    ->
        broadcast(gana_punto(Nombre)),
        CartaSelec = abandono
    ).
pedir_respuesta_a_rival(NombreCanta, Canto, Acepto) :-
    jugadores(Jugadores),

    member(jugador(NombreRival, _, _, _, WSRival), Jugadores),
    NombreRival \= NombreCanta,

    enviar(WSRival, responder_truco(NombreCanta, Canto)),

    ws_receive(WSRival, Mensaje, []),
    term_string(Term, Mensaje.data),

    (
        Term = respuesta_truco(quiero)
    ->
        Acepto = si

    ;
        Term = respuesta_truco(no_quiero)
    ->
        Acepto = no
    ).

enviar(WS, Termino) :-
    term_string(Termino, Msg),
    ws_send(WS, text(Msg)).

broadcast(Termino) :-
    jugadores(Todos),
    forall(
        member(jugador(_, _, _, _, WS), Todos),
        catch(enviar(WS, Termino), _, true)
    ).

%-----------------------------------------------------------------
%                       DETERMINAR GANADOR RONDA
%-----------------------------------------------------------------
carta_ganadora(Carta1,Carta2):-
% este predicado comprueba si los puntos de la primer carta es mayor a la segunda carta pasada por parametro. 
    puntos_carta_truco(Carta1, Puntos1),
    puntos_carta_truco(Carta2, Puntos2),
    Puntos1 > Puntos2.

    

mejor_carta(X, Y, Z) :-
% este predicado toma la carta del jugador mano y la compara con la de su rival en termino de sus puntos, se retorna en Z la carta ganadora, 
% en caso de empate de puntos gana el jugador mano 
    ( carta_ganadora(X, Y) ->
        Z = X;
        Z = Y
    ).

ganador_ronda(Cartas, WinnerCard) :-
% este predicado recorre las cartas jugadas por cada jugador y calcula la carta ganadora
    reverse(Cartas, [FirstCard|RestCards]),
    foldl(mejor_carta, RestCards, FirstCard, WinnerCard).


