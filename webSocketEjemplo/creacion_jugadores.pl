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
    jugadores(JugadoresConCartas),
    forall(member(jugador(_,_,_,_,WS), Jugadores),
           ws_send(WS, text("Juego iniciado!"))),
    jugar_rondas(JugadoresConCartas, 1, 3). % 2 rondas.

jugar_rondas(Jugadores, Ronda, MaxRondas) :-
    Ronda > MaxRondas;
    Jugadores= [jugador(_,_,_,X,_)|_], length(X, N), N > 1,
    !,
    format("Juego terminado~n", []),
    % Notificar a todos los jugadores y cerrar conexiones
    forall(member(jugador(_,_,_,_,WS), Jugadores),
           ws_send(WS, text("Juego terminado!"))
            ),
    assertz(juego(terminado)).



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

    % agregar_carta_win(WinnerCard, WinnerPlayer0, WinnerPlayer),
    % nth0(N, JugadoresFinal, WinnerPlayer, JugadoresNext),

    % retractall(jugadores(_)),
    % assertz(jugadores(JugadoresFinal)),

    % WinnerPlayer = jugador(WinnerName, _, _, _, _),
    format("Carta Ganadora es ~w from ~w~n", [WinnerCard, WinnerName]),

    SigRonda is Ronda + 1,
    jugar_rondas(JugadoresFinal, SigRonda, MaxRondas).



quitar_carta(JugadorIn, CartaJugada, JugadorOut) :-
    JugadorIn = jugador(Nombre, Cartas, CartasJugadas, CartasWin, WebSocket),
    select(CartaJugada, Cartas, CartasOut),
    JugadorOut = jugador(Nombre, CartasOut, [CartaJugada|CartasJugadas], CartasWin, WebSocket).

procesar_turnos([],[], Ronda ):-
    format("Todos los jugadores han jugado en ronda ~w~n", [Ronda]).

procesar_turnos([jugador(Nombre,Cartas,_,_,WS)|Resto],[CartaSelec|CartasSelec] ,Ronda) :-
    
    format("Turno de ~w en ronda ~w~n", [Nombre, Ronda]),
    % Notificar a todos
    jugadores(TodosJugadores),
    atom_concat('Turno de ', Nombre, MsgTurno),
    forall(member(jugador(_,_,_,_,WSAll), TodosJugadores),
           ws_send(WSAll, text(MsgTurno))),
    % Enviar Opciones
    ws_send(WS, text("tu_turno")),

    % Pedir jugada al jugador actual con multiples intentos

    ws_send(WS, prolog(cartas(Cartas))),
    % Recibir respuesta con timeout mas corto y reintentos
    ws_receive(WS, Respuesta, []),
    term_string(ResCarta, Respuesta.data),
    ResCarta= carta(CartaSelec),
    
    member(CartaSelec, Cartas),
    format("~w jugo: ~w~n", [Nombre, CartaSelec]),
    % Notificar la jugada a todos con manejo de errores
    format(atom(MsgJugada), "~w eligio ~w", [Nombre, CartaSelec]),
    forall(member(jugador(_,_,_,_,WSAll), TodosJugadores),
	   catch(ws_send(WSAll, text(MsgJugada)), _, true)),
    procesar_turnos(Resto, CartasSelec, Ronda).

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

