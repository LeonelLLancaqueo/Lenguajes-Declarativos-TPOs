:- module(fixture, [inicio/0,lista_matches//1]).

:- use_module(library(http/http_server)).
:- use_module(library(http/html_write)).         % generación de HTML
:- use_module(library(http/html_head)).
:- use_module(library(http/js_write)).
:- use_module(library(persistency)).
%:- use_module(library(http/http_log)).
:- use_module(library(clpfd)).

:- persistent
    partido( id:integer,
             equipoA:any,
             equipoB:any,
             fecha:atom,
             estado:oneof([proximo,jugado])
           ),
    resultado( id:integer,
               goles:compound,    % representamos G-A-B con un término GA-GB
               penales:compound   % representamos P-A-B con un término PA-PB
             ).


:- use_module(library(apply)).    % include/3
:- use_module(library(lists)).    % sum_list/2, setof/3


% ——————————————————————————————————————————————————
% Definición completa de grupos A–L y partidos de fase de grupos
% IDs 1–72
% ——————————————————————————————————————————————————
:- dynamic grupo/2.
% Grupo A
grupo('México','A').        grupo('Sudáfrica','A').
grupo('Corea del Sur','A'). grupo('Chequia','A').
% Grupo B
grupo('Canadá','B').        grupo('Bosnia y Herzegovina','B').
grupo('Qatar','B').         grupo('Suiza','B').
% Grupo C
grupo('Brasil','C').        grupo('Marruecos','C').
grupo('Haití','C').         grupo('Escocia','C').
% Grupo D
grupo('Estados Unidos','D'). grupo('Turquía','D').
grupo('Australia','D').     grupo('Paraguay','D').
% Grupo E
grupo('Alemania','E').      grupo('Curazao','E').
grupo('Costa de Marfil','E'). grupo('Ecuador','E').
% Grupo F
grupo('Países Bajos','F').  grupo('Japón','F').
grupo('Suecia','F').      grupo('Túnez','F').
% Grupo G
grupo('Bélgica','G').       grupo('Egipto','G').
grupo('Irán','G').          grupo('Nueva Zelanda','G').
% Grupo H
grupo('España','H').        grupo('Cabo Verde','H').
grupo('Arabia Saudita','H'). grupo('Uruguay','H').
% Grupo I
grupo('Francia','I').       grupo('Senegal','I').
grupo('Irak','I').           grupo('Noruega','I').
% Grupo J
grupo('Argentina','J').     grupo('Argelia','J').
grupo('Austria','J').       grupo('Jordania','J').
% Grupo K
grupo('Portugal','K').      grupo('RD Congo','K').
grupo('Uzbekistán','K').    grupo('Colombia','K').
% Grupo L
grupo('Inglaterra','L').    grupo('Croacia','L').
grupo('Ghana','L').         grupo('Panamá','L').


%%% ––––––––––––––––––––––––––––––––––––––––––––––––
%%% Utils para eliminación directa
%%% ––––––––––––––––––––––––––––––––––––––––––––––––
% Recolecta tercer lugar de cada grupo y ordena para mejores 8

gruponumber('A',1). gruponumber('B',2). gruponumber('C',3). gruponumber('D',4).
gruponumber('E',5). gruponumber('F',6). gruponumber('G',7). gruponumber('H',8).
gruponumber('I',9). gruponumber('J',10). gruponumber('K',11). gruponumber('L',12).


terceros(Grupo,EquipoResp) :-
    member(g(Grupo,Resp),[g('E',E),g('I',I),g('A',A),g('L',L),g('G',G),g('D',D),g('B',B),g('K',K)]),
    Terceros = [E,I,A,L,G,D,B,K],
    Terceros ins 1..12,
    all_distinct(Terceros),
    E #\= 5, E #\= 7, E #\= 8, E #\= 9, E #\= 10, E #\= 11, E #\= 12,
    %    (	E #= 1 ; E #= 2 ; E #= 3 ; E #= 4 ; E #= 6 ), % Grupo A/B/C/D/F
    I #\= 1, I #\= 2, I #\= 5, I #\= 9, I #\= 10, I #\= 11, I #\= 12,
    %    (	I #= 3 ; I #= 4 ; I #= 6 ; I #= 7 ; I #= 8 ), % Grupo C/D/F/G/H
    A #\= 1, A #\= 2, A #\= 4, A #\= 7, A #\= 10, A #\= 11, A #\= 12,
    %    (	A #= 3 ; A #= 5 ; A #= 6 ; A #= 8 ; A #= 9 ), % Grupo C/E/F/H/I 
    L #\= 1, L #\= 2, L #\= 3, L #\= 4, L #\= 6, L #\= 7,  L #\= 12,
    %    (	L #= 5 ; L #= 8 ; L #= 9 ; L #= 10 ; L #= 11 ), % Grupo E/H/I/J/K
    G #\= 2, G #\= 3, G #\= 4, G #\= 6, G #\= 7, G #\= 11, G #\= 12,
    %    (	G #= 1 ; G #= 5 ; G #= 8 ; G #= 9 ; G #= 10 ), % Grupo A/E/H/I/J
    D #\= 1, D #\= 3, D #\= 4, D #\= 7, D #\= 8, D #\= 11, D #\= 12,
    %(	D #= 2 ; D #= 5 ; D #= 6 ; D #= 9 ; D #= 10 ), % Grupo B/E/F/I/J
    B #\= 1, B #\= 2, B #\= 3, B #\= 4, B #\= 8, B #\= 11, B #\= 12,
    %    (	B #= 5 ; B #= 6 ; B #= 7 ; B #= 9 ; B #= 10 ), % Grupo E/F/G/I/J
    K #\= 1, K #\= 2, K #\= 3, K #\= 6, K #\= 7, K #\= 8, K #\= 11,
    %    (	K #= 4 ; K #= 5 ; K #= 9 ; K #= 10 ; K #= 12 ), % Grupo D/E/I/J/L
    mejores_terceros(T),maplist(grupo,T,Grupos),maplist(gruponumber,Grupos,Numeros),
    member(E,Numeros),member(I,Numeros),member(A,Numeros),
    member(L,Numeros),member(G,Numeros),member(D,Numeros),
    member(B,Numeros),member(K,Numeros),
    gruponumber(Gruporesp,Resp),grupo(EquipoResp,Gruporesp),
    member(EquipoResp,T).




    

mejores_terceros(Terceros) :-
  grupos(Grs),
  findall([Pts,GD,GF,Equipo],
    ( member(G, Grs),
      findall([Pts1,GD1,GF1,Equipo1],
              (   grupo(Equipo1,G),estadisticas(Equipo1,[_ ,_,_,_,GF1,_,GD1,Pts1]) ), D),
      sort(D,SD),
      nth0(1,SD, [Pts,GD,GF,Equipo])  % tercer lugar
		),
      L),
  sort(0,@>=,L,Desc),
  Desc = [[_,_,_,Eq1] ,[_,_,_,Eq2],[_,_,_,Eq3] ,[_,_,_,Eq4],[_,_,_,Eq5] ,[_,_,_,Eq6],[_,_,_,Eq7] ,[_,_,_,Eq8]|_],
  Terceros = [Eq1,Eq2,Eq3,Eq4,Eq5,Eq6,Eq7,Eq8].


% Resolver placeholders de equipos
resolver_equipo(ganador(G), Equipo) :-
    findall([P,GD,GF,Eq], ( grupo(Eq,G), estadisticas(Eq,[_ ,_,_,_,GF,_,GD,P]) ), D),
  sort(D,SD),    
  last(SD, [_,_,_,Equipo]).  % ganador = mayor Pts/GD/GF

resolver_equipo(segundo(G), Equipo) :-
    findall([P,GD,GF,Eq], ( grupo(Eq,G), estadisticas(Eq,[_ ,_,_,_,GF,_,GD,P]) ), D),
    sort(D,SD),
  nth0(2, SD, [_,_,_,Equipo]).

resolver_equipo(mejor_tercero(N), Equipo) :-
    terceros(N,Equipo),!.

resolver_equipo(ganador_partido(Id),Equipo) :-
  ganador(Id,Equipo).


resolver_equipo(perdedor_partido(Id),Equipo) :-
    partido(Id,A,B,_,Estado),
    (
	Estado == jugado
    ->
	resultado(Id,GA-GB,PA-PB),
	( GA > GB -> Equipo = B
	; GA < GB -> Equipo = A
	; PA > PB -> Equipo = B
	; Equipo = A
	)
    ;
	Equipo = 'Sin Determinar'
    ).

ganador(Id,Equipo) :-
    partido(Id,A,B,_,Estado),
    (
	Estado == jugado
    ->
	resultado(Id,GA-GB,PA-PB),
	( GA > GB -> Equipo = A
	; GA < GB -> Equipo = B
	; PA > PB -> Equipo = A
	; Equipo = B
	)
    ;
	Equipo = 'Sin Determinar'
    ).


% Nombre final de un término (si ya es átomo, queda igual)
nombre_equipo(E,N) :- atom(E), !, N=E.
nombre_equipo(E,N) :- resolver_equipo(E,N).

% punto de entrada que llama a http_server/2
inicio :-
    initialize('estado_mundial.pl'),
    http_server(http_dispatch, [port(8080)]).

:- http_handler(root(.),           mostrar_fixture,   []).
:- http_handler(root(resultar),    agregar_resultado, [method(post)]).
:- http_handler(root(resultados),  mostrar_resultados,[]).
:- http_handler(root(tabla),       mostrar_tabla,     []).
:- http_handler(root(api/tabla), api_tabla, [method(post)]).
:- http_handler(root(eliminatorias), mostrar_eliminatorias, []).

mostrar_fixture(_Req) :-
%    cargar_estado_usuarios,
    findall(partido(Id,EA,EB,Fecha),(
		partido(Id,A,B,Fecha,proximo),
		nombre_equipo(A,EA),
		nombre_equipo(B,EB)
			     ),
		Partidos),
    sort(4, @=<, Partidos, PartidosOrdenados),
    findall(p(ID, NomA, NomB, Fecha, GolesA, GolesB, PenalesA, PenalesB),
	    (	member(partido(ID, NomA, NomB, Fecha),PartidosOrdenados),
		atomic_concat('Goles ', NomA, GolesA),
		atomic_concat('Goles ', NomB, GolesB),
		atomic_concat('Penales ', NomA, PenalesA),
		atomic_concat('Penales ', NomB, PenalesB)
	    ),
            Filas),
    reply_html_page(
	[  title('Fixture Mundial 2026'),
	   \style 
      ],
	[ \menu ,
	  div([class("w3-container w3-padding-16")],[
        h1([class('w3-text-indigo')],"Próximos Partidos"),
        table(class("w3-table w3-striped w3-hoverable"),[
	      tr(class("w3-light-blue"),[
		     th('ID'),
		     th('Equipo A'),
		     th('Equipo B'),
		     th('Fecha')
		 ]),
	      \filas_partidos(Filas)
             ])
				    ])
      ]).

filas_partidos([]) --> [].
filas_partidos([p(ID, NomA, NomB, Fecha, GolesA, GolesB, PenalesA, PenalesB)|Rest]) -->
    html([tr([onclick="document.getElementById('ed"+ID+"').style.display='block'",style("cursor:pointer")],[
                       td(ID),
                       td(NomA),
                       td(NomB),
                       td(Fecha)
                     ]),
		  div([id="ed"+ID,class="w3-modal "],
		      div([class="w3-modal-content w3-animate-top w3-card-4",style('width:400px')],
			  [
			      header(class("w3-container w3-blue"),[
								       span([onclick="document.getElementById('ed"+ID+"').style.display='none'",class="w3-button w3-display-topright"],"X"),
								       h2([class('w3-text-indigo')],"Cargar Resultado")
								   ]),
			      form([id="f"+ID,action('/resultar'),method('POST'),class("w3-container")],
				   div(class="w3-section",[
							      div([class('w3-row-padding'),style('font-size:25px')],[
															div(class('w3-half w3-right-align w3-margin-top'),label(b('Partido Nro:'))),
															div(class('w3-half '),b(input([class('w3-input'),style('width:60px'),type(text),value(ID),name(id),readonly],[])))
														    ]),
							      div(class('w3-row-padding'),[
											      div(class('w3-half w3-margin-bottom'),
												  [
												      label(b(GolesA)),
												      input([class('w3-input  w3-border w3-margin-bottom'),style('width:100px'),type(number),min(0),name(gola),value(0),required],[])
												  
												  ]),
											      div(class('w3-half w3-margin-bottom'),
												  [
												      label(b(GolesB)),
												      input([class('w3-input  w3-border w3-margin-bottom'),style('width:100px'),type(number),min(0),name(golb),value(0),required],[])
												  ])
											  
											  ]),
							      div(class('w3-row-padding'),[
											      div(class('w3-half w3-margin-bottom'),
												  [
												      label(b(PenalesA)),
												      input([class('w3-input  w3-border w3-margin-bottom'),style('width:100px'),type(number),min(0),name(pena),value(0)],[])
												  ]),
											      div(class('w3-half w3-margin-bottom'),
												  [
												      label(b(PenalesB)),
												      input([class('w3-input  w3-border w3-margin-bottom'),style('width:100px'),type(number),min(0),name(penb),value(0)],[])
												  ])
											  ])])),
			      footer(class("w3-container w3-blue"),button([form="f"+ID,class('w3-button w3-block w3-light-blue w3-section w3-padding'),type(submit)],"CARGAR"))
			  ])),
		  \filas_partidos(Rest)
	 ]).




agregar_resultado(Request) :-
    http_parameters(Request, [
			id(Id,[integer]),
			gola(GA,[integer]),
			golb(GB,[integer]),
			pena(PA,[integer]),
			penb(PB,[integer])
		       ]),
    retract_partido(Id, A, B,Fecha, proximo),
    nombre_equipo(A, NA),nombre_equipo(B, NB),
    assert_partido(Id, NA, NB, Fecha, jugado),
    assert_resultado(Id, GA-GB, PA-PB),
    reply_html_page(
	[ title('Resultado Cargado'),
	  \style
      ],
	[  \menu ,
	   	  div([class("w3-container w3-padding-16")],[
        h1([class('w3-text-indigo')],'¡Resultado registrado!'),
        p(['Partido ', Id, ': ', NA, ' ', GA, ' - ', GB, ' ', NB]),
        a(href('/'), 'Volver al fixture')
							    ])
      ]).

mostrar_resultados_por_grupo(Grupo) -->
     {  findall(r(ID, A, B, GA, GB, PA, PB, Fecha),
					( partido(ID,A,B,Fecha,jugado),
					  resultado(ID,GA-GB,PA-PB),
					  grupo(A,Grupo)
					),
					Resultados)
     },
     html([
	      div([class("w3-container w3-padding-16")],[
      h3([class('w3-text-indigo')],'Resultados Registrados'),
      table(class('w3-table w3-striped'),
	    [
		tr(class('w3-light-blue'),[th('ID'),th('A'),th('B'),th('Goles A'),th('Goles B'),th('Pen A'),th('Pen B'),th('Fecha')]),
		\filas_resultados(Resultados)
	     ]
	   )
							])
	      ]).

mostrar_resultados(_Req) :-
   findall(r(ID, A, B, GA, GB, PA, PB, Fecha),
					( partido(ID,A,B,Fecha,jugado),
						resultado(ID,GA-GB,PA-PB)
					),
					Resultados), 
  reply_html_page(
      [ title('Resultados Mundial 2026'),
	\style 
    ],
      [ \menu ,
	div([class("w3-container w3-padding-16")],[		   

      h1([class('w3-text-indigo')],'Resultados Registrados'),
      table(class('w3-table w3-striped'),
	    [
		tr(class('w3-light-blue'),[th('ID'),th('A'),th('B'),th('Goles A'),th('Goles B'),th('Pen A'),th('Pen B'),th('Fecha')]),
		\filas_resultados(Resultados)
	     ]
	   )
						  ])
    ]).

filas_resultados([]) --> [].
filas_resultados([r(ID, A, B, GA, GB, PA, PB, Fecha)|Rest]) -->
		html([tr([ td(ID),
							td(A), td(B),
							td(GA), td(GB),
							td(PA), td(PB),
							td(Fecha)
			]),
		      \filas_resultados(Rest)]).


% Lista de todos los grupos
grupos(Lista) :-
  setof(G, Equipo^grupo(Equipo,G), Lista).

% Estadísticas [PJ,PG,PE,PP,GF,GC,GD,Pts] de un Equipo
estadisticas(Equipo,[PJ,PG,PE,PP,GF,GC,GD,Pts]) :-
  findall([RGA,RGB,Res],
	  ( partido(Id,A,B,_,jugado),
	    Id < 73,  % solo fase de grupos
	    resultado(Id,GA-GB,_PA-_PB),
	    ( A==Equipo -> RGA=GA, RGB=GB ; B==Equipo -> RGA=GB, RGB=GA ),
	    ( RGA>RGB -> Res=win
	    ; RGA<RGB -> Res=loss
	    ; Res=tie
	    )
	  ),
	  Partidos),
  length(Partidos,PJ),
  include([X]>>(X=[_,_,win]),  Partidos,W), length(W,PG),
  include([X]>>(X=[_,_,tie]),  Partidos,T), length(T,PE),
  include([X]>>(X=[_,_,loss]), Partidos,L), length(L,PP),
  findall(X, member([X,_,_],Partidos), L1), sum_list(L1,GF),
  findall(Y, member([_,Y,_],Partidos), L2), sum_list(L2,GC),
  GD is GF-GC,
  Pts is PG*3 + PE.



% DCG que genera la tabla de posiciones de un grupo
generar_tabla(G) -->
  { setof(E, grupo(E,G), Equipos),
    findall([Pts,GD,Equipo,PJ,PG,PE,PP,GF,GC],
      ( member(Equipo,Equipos),
        estadisticas(Equipo,[PJ,PG,PE,PP,GF,GC,GD,Pts])
      ),
    Datos),
    sort(1,@>=,Datos,Ordenado)
  },
  html([
    h2([class('w3-text-indigo')],['Grupo ', G]),
    table([class('w3-table w3-striped')],
      [ tr(class('w3-light-blue'),[ th('Equipo'),th('PJ'),th('PG'),th('PE'),th('PP'),
            th('GF'),th('GC'),th('DG'),th('Pts') ])
      | \filas_estadisticas(Ordenado)
      ]
    ),
    br([]),
    \mostrar_resultados_por_grupo(G)
  ]).


filas_estadisticas([]) --> [].
filas_estadisticas([[Pts,GD,Equipo,PJ,PG,PE,PP,GF,GC]|Rest]) -->
  html(tr([ td(Equipo), td(PJ), td(PG), td(PE),
            td(PP), td(GF), td(GC), td(GD), td(Pts) ])),
  filas_estadisticas(Rest).

style --> 
    html(
	[
            \html_requires("https://www.w3schools.com/w3css/5/w3.css")
	]).



menu -->
    html([div(class('w3-top'),div(class('w3-bar w3-blue'),[
		 a([class('w3-bar-item w3-button'),href('/')],        'Próximos'),
		 a([class('w3-bar-item w3-button'),href('/resultados')],'Resultados'),
		 a([class('w3-bar-item w3-button'),href('/tabla')],     'Tabla de Posiciones'),
		 a([class('w3-bar-item w3-button'),href('/eliminatorias')], 'Eliminatorias')
				 ])),	'<br><br>']
	).

api_tabla(Request) :-
    http_read_json_dict(Request, JsonDict),
%    http_log("lo que viene de grupo es ~w",[JsonDict]),
    atom_string(Grupo,JsonDict.grupo),
    phrase(html([\generar_tabla(Grupo)]),HTML),
    format('Content-type: text/html~n~n'),
    print_html(HTML).

    
    

mostrar_tabla(_Req) :-
  grupos(Grps),
  reply_html_page(
      [ title('Tabla de Posiciones'),
	\style
    ],
      [ \menu ,
	div([class("w3-container w3-padding-16")],[

	h1([class('w3-text-indigo')],'Tabla de Posiciones por Grupo'),
	div([class('w3-bar')],[
				  \generar_botones_tablas(Grps)
			      ]),
	div([id=regiontable],[])
						  ]),
	\js_script({|javascript||
		    window.onload = function() {
					     gentabla('A');
					 };

				function fetchajax(url,data,dom) {
				    fetch(url ,{
					      method: "POST",
					      headers: {
						  "Content-Type": "application/json"
					      },
					      body: JSON.stringify(data)
					  })
				    .then(response => response.text())
				    .then(html => {
					      document.getElementById(dom).innerHTML = html;
					  });
			 	};

				function gentabla(grupo) {
							     fetchajax("api/tabla",{
						grupo: grupo } , "regiontable")
							 };
		     
			 
		    |})
    ]).

generar_botones_tablas([]) --> [].
generar_botones_tablas([G|Grupos]) -->
    html([
	     button([class('w3-button w3-bar-item'), onclick("gentabla('~s')"-[G])],G),
	     \generar_botones_tablas(Grupos)
	     ]).

initialize(File):-
        (
	exists_file(File)
        -> 
        db_attach(File,[])
        ;
	(   
        db_attach(File,[]),
% ————————————
% Partidos G. A (IDs 1–6)
% ————————————
assert_partido(1, 'México',         'Sudáfrica',          '2026-06-11 16:00', proximo),
assert_partido(2, 'Corea del Sur',  'Chequia',           '2026-06-11 23:00', proximo),
assert_partido(3, 'Chequia',       'Sudáfrica',          '2026-06-18 13:00', proximo),
assert_partido(4, 'México',         'Corea del Sur',      '2026-06-18 22:00', proximo),
assert_partido(5, 'Chequia',       'México',             '2026-06-24 22:00', proximo),
assert_partido(6, 'Sudáfrica',      'Corea del Sur',      '2026-06-24 22:00', proximo),

% ————————————
% Partidos G, B (7–12)
% ————————————
assert_partido(7,  'Canadá',        'Bosnia y Herzegovina',           '2026-06-12 16:00', proximo),
assert_partido(8,  'Qatar',         'Suiza',              '2026-06-12 16:00', proximo),
assert_partido(9,  'Suiza',         'Bosnia y Herzegovina',           '2026-06-18 16:00', proximo),
assert_partido(10, 'Canadá',        'Qatar',              '2026-06-18 19:00', proximo),
assert_partido(11, 'Suiza',         'Canadá',             '2026-06-24 16:00', proximo),
assert_partido(12, 'Bosnia y Herzegovina',      'Qatar',              '2026-06-24 16:00', proximo),

% ————————————
% Partidos G, C (13–18)
% ————————————
assert_partido(13, 'Brasil',       'Marruecos',          '2026-06-13 19:00', proximo),
assert_partido(14, 'Haití',        'Escocia',            '2026-06-13 22:00', proximo),
assert_partido(15, 'Brasil',       'Haití',              '2026-06-19 19:00', proximo),
assert_partido(16, 'Escocia',      'Marruecos',          '2026-06-19 22:00', proximo),
assert_partido(17, 'Escocia',      'Brasil',             '2026-06-24 19:00', proximo),
assert_partido(18, 'Marruecos',    'Haití',              '2026-06-24 19:00', proximo),

% ————————————
% Partidos G, D (19–24)
% ————————————
assert_partido(19, 'Estados Unidos','Turquía',         '2026-06-12 22:00', proximo),
assert_partido(20, 'Australia',     'Paraguay',          '2026-06-13 01:00', proximo),
assert_partido(21, 'Turquía',      'Paraguay',          '2026-06-19 16:00', proximo),
assert_partido(22, 'Estados Unidos','Australia',         '2026-06-19 01:00', proximo),
assert_partido(23, 'Turquía',      'Estados Unidos',    '2026-06-25 23:00', proximo),
assert_partido(24, 'Paraguay',      'Australia',         '2026-06-25 23:00', proximo),

% ————————————
% Partidos G, E (25–30)
% ————————————
assert_partido(25, 'Alemania',      'Curazao',           '2026-06-14 14:00', proximo),
assert_partido(26, 'Costa de Marfil','Ecuador',          '2026-06-14 20:00', proximo),
assert_partido(27, 'Alemania',      'Costa de Marfil',   '2026-06-20 17:00', proximo),
assert_partido(28, 'Curazao',       'Ecuador',           '2026-06-20 21:00', proximo),
assert_partido(29, 'Ecuador',       'Alemania',          '2026-06-25 17:00', proximo),
assert_partido(30, 'Curazao',       'Costa de Marfil',   '2026-06-25 17:00', proximo),

% ————————————
% Partidos G, F (31–36)
% ————————————
assert_partido(31, 'Países Bajos',  'Japón',             '2026-06-14 17:00', proximo),
assert_partido(32, 'Suecia',      'Túnez',             '2026-06-14 23:00', proximo),
assert_partido(33, 'Países Bajos',  'Suecia',          '2026-06-20 14:00', proximo),
assert_partido(34, 'Japón',         'Túnez',             '2026-06-20 01:00', proximo),
assert_partido(35, 'Túnez',         'Países Bajos',      '2026-06-25 20:00', proximo),
assert_partido(36, 'Japón',         'Suecia',          '2026-06-25 20:00', proximo),

% ————————————
% Partidos G, G (37–42)
% ————————————
assert_partido(37, 'Bélgica',       'Egipto',            '2026-06-15 19:00', proximo),
assert_partido(38, 'Irán',          'Nueva Zelanda',     '2026-06-15 22:00', proximo),
assert_partido(39, 'Bélgica',       'Irán',              '2026-06-21 16:00', proximo),
assert_partido(40, 'Egipto',        'Nueva Zelanda',     '2026-06-21 22:00', proximo),
assert_partido(41, 'Nueva Zelanda','Bélgica',            '2026-06-26 00:00', proximo),
assert_partido(42, 'Egipto',        'Irán',              '2026-06-26 00:00', proximo),

% ————————————
% Partidos G, H (43–48)
% ————————————
assert_partido(43, 'España',        'Cabo Verde',        '2026-06-15 13:00', proximo),
assert_partido(44, 'Arabia Saudita','Uruguay',           '2026-06-15 19:00', proximo),
assert_partido(45, 'España',        'Arabia Saudita',    '2026-06-21 13:00', proximo),
assert_partido(46, 'Cabo Verde',    'Uruguay',           '2026-06-21 19:00', proximo),
assert_partido(47, 'Uruguay',       'España',            '2026-06-26 21:00', proximo),
assert_partido(48, 'Cabo Verde',    'Arabia Saudita',    '2026-06-26 21:00', proximo),

% ————————————
% Partidos G, I (49–54)
% ————————————
assert_partido(49, 'Francia',       'Senegal',           '2026-06-16 16:00', proximo),
assert_partido(50, 'Irak',   'Noruega',           '2026-06-16 19:00', proximo),
assert_partido(51, 'Francia',       'Irak',       '2026-06-22 18:00', proximo),
assert_partido(52, 'Noruega',       'Senegal',           '2026-06-22 21:00', proximo),
assert_partido(53, 'Noruega',       'Francia',           '2026-06-26 16:00', proximo),
assert_partido(54, 'Senegal',       'Irak',       '2026-06-26 16:00', proximo),

% ————————————
% Partidos G, J (55–60)
% ————————————
assert_partido(55, 'Argentina',     'Argelia',           '2026-06-16 22:00', proximo),
assert_partido(56, 'Austria',       'Jordania',          '2026-06-17 01:00', proximo),
assert_partido(57, 'Argentina',     'Austria',           '2026-06-22 14:00', proximo),
assert_partido(58, 'Jordania',      'Argelia',           '2026-06-22 00:00', proximo),
assert_partido(59, 'Jordania',      'Argentina',         '2026-06-27 23:00', proximo),
assert_partido(60, 'Argelia',       'Austria',           '2026-06-27 23:00', proximo),

% ————————————
% Partidos G, K (61–66)
% ————————————
assert_partido(61, 'Portugal',      'RD Congo',       '2026-06-17 14:00', proximo),
assert_partido(62, 'Uzbekistán',    'Colombia',          '2026-06-17 23:00', proximo),
assert_partido(63, 'Portugal',      'Uzbekistán',        '2026-06-23 14:00', proximo),
assert_partido(64, 'RD Congo',   'Colombia',          '2026-06-23 23:00', proximo),
assert_partido(65, 'Colombia',      'Portugal',          '2026-06-27 20:30', proximo),
assert_partido(66, 'RD Congo',   'Uzbekistán',        '2026-06-27 20:30', proximo),

% ————————————
% Partidos G, L (67–72)
% ————————————
assert_partido(67, 'Inglaterra',    'Croacia',           '2026-06-17 17:00', proximo),
assert_partido(68, 'Ghana',         'Panamá',            '2026-06-17 20:00', proximo),
assert_partido(69, 'Inglaterra',    'Ghana',             '2026-06-23 17:00', proximo),
assert_partido(70, 'Croacia',       'Panamá',            '2026-06-23 20:00', proximo),
assert_partido(71, 'Panamá',        'Inglaterra',        '2026-06-27 18:00', proximo),
assert_partido(72, 'Croacia',       'Ghana',             '2026-06-27 18:00', proximo),

%%% ––––––––––––––––––––––––––––––––––––––––––––––––
%%% Hechos partido/5 para eliminación directa
%%% ––––––––––––––––––––––––––––––––––––––––––––––––
% 16avos de final (IDs 73–80 según tu txt)
assert_partido(73, ganador('A'), segundo('B'), '2026-06-28 16:00', proximo),
assert_partido(74, ganador('E'), mejor_tercero('E'), '2026-06-29 17:30', proximo),
assert_partido(75, ganador('F'), segundo('C'), '2026-06-29 22:00', proximo),
assert_partido(76, ganador('C'), segundo('F'), '2026-06-29 14:00', proximo),
assert_partido(77, ganador('I'), mejor_tercero('I'), '2026-06-30 18:00', proximo),
assert_partido(78, segundo('E'), segundo('I'), '2026-06-30 14:00', proximo),
assert_partido(79, ganador('A'), mejor_tercero('A'), '2026-06-30 22:00', proximo),
assert_partido(80, ganador('L'), mejor_tercero('L'), '2026-07-01 13:00', proximo),
assert_partido(81, ganador('D'), mejor_tercero('D'), '2026-07-01 21:00', proximo),
assert_partido(82, ganador('G'), mejor_tercero('G'), '2026-07-01 13:00', proximo),
assert_partido(83, segundo('K'), segundo('L'), '2026-07-02 20:00', proximo),
assert_partido(84, ganador('H'), segundo('J'), '2026-07-02 16:00', proximo),
assert_partido(85, ganador('B'), mejor_tercero('B'), '2026-07-03 00:00', proximo),
assert_partido(86, ganador('J'), segundo('H'), '2026-07-03 19:00', proximo),
assert_partido(87, ganador('K'), mejor_tercero('K'), '2026-07-03 22:30', proximo),
assert_partido(88, segundo('D'), segundo('G'), '2026-07-03 15:00', proximo),


% Octavos de final (IDs 89–96)
assert_partido(89, ganador_partido(74), ganador_partido(77), '2026-07-04 18:00', proximo),
assert_partido(90, ganador_partido(73), ganador_partido(75), '2026-07-04 14:00', proximo),
assert_partido(91, ganador_partido(76), ganador_partido(78), '2026-07-05 17:00', proximo),
assert_partido(92, ganador_partido(79), ganador_partido(80), '2026-07-05 21:00', proximo),
assert_partido(93, ganador_partido(83), ganador_partido(84), '2026-07-06 16:00', proximo),
assert_partido(94, ganador_partido(81), ganador_partido(82), '2026-07-06 21:00', proximo),
assert_partido(95, ganador_partido(86), ganador_partido(88), '2026-07-07 13:00', proximo),
assert_partido(96, ganador_partido(85), ganador_partido(87), '2026-07-07 17:00', proximo),

% Cuartos de final (IDs 97–100)
assert_partido(97, ganador_partido(89), ganador_partido(90), '2026-07-09 17:00', proximo),
assert_partido(98, ganador_partido(93), ganador_partido(94), '2026-07-10 16:00', proximo),
assert_partido(99, ganador_partido(91), ganador_partido(92), '2026-07-11 18:00', proximo),
assert_partido(100,ganador_partido(95), ganador_partido(96), '2026-07-11 22:00', proximo),

% Semifinales (IDs 101–102)
assert_partido(101, ganador_partido(97), ganador_partido(98), '2026-07-14 16:00', proximo),
assert_partido(102, ganador_partido(99), ganador_partido(100),'2026-07-15 16:00', proximo),

% Tercer puesto y Final
assert_partido(103, perdedor_partido(101), perdedor_partido(102), '2026-07-18 18:00', proximo),
assert_partido(104, ganador_partido(101), ganador_partido(102), '2026-07-19 16:00', proximo)
)).

        
        
mostrar_eliminatorias(_Req) :-
    % definimos etapas y sus IDs
    Etapas = [
      '16avos'        -(73-88) / 1 , 
       'Octavos'       -(89-96) / 118, 
       'Cuartos'       -(97-100) / 356,
       'Semifinales'   -(101-102) / 820,
       'Tercer puesto' -(103) / 100,
       'Final'         -(104) / 100
    ],
    reply_html_page(
	[ title('Eliminatorias Mundial 2026'),
	  \style
      ],
	[  \menu,
	  div([class("w3-container w3-padding-16")],[
	   h1([class('w3-text-indigo')],'Eliminatorias')
						    , div([class("w3-flex"),style("gap:10px")], \generar_eliminatorias(Etapas))
						    ])
						    ]
    ).

generar_eliminatorias([]) --> [].
generar_eliminatorias([Nombre-(Rango) / Gap |Rest]) -->
    html(div([style("align-self:center;margin-right:30px")],
      [ h2([class('w3-text-indigo')],Nombre)
      , div([class("w3-flex"),style("gap:~dpx;flex-direction:column"-[Gap])], \matches(Rango)  )
      ])),
    generar_eliminatorias(Rest).

% Rango puede ser Start-End o lista fija [Id]
matches(Start-End) --> !,
    { findall(Id, between(Start, End, Id), L) },
    lista_matches(L).
matches(Id) --> !,
    lista_matches([Id]).		


lista_matches([]) --> [].
lista_matches([Id|T]) -->
    { partido(Id,Araw,Braw,_,Estado),
      nombre_equipo(Araw, A),
      nombre_equipo(Braw, B),
      ( Estado == jugado, resultado(Id,GA-GB,PA-PB),
	atom_string(GA, GAS), atom_string(GB, GBS)
      ->
      (	  GA == GB ->
	  atomic_list_concat([GAS,'(',PA,') - ', GBS,'(',PB,')'], Score)
			;
			atomic_list_concat([GAS, '-', GBS], Score)
      ),
      
       ganador(Id,EquipoGanador),
       (   EquipoGanador == A -> TeamA = 'w3-light-blue', TeamB = 'w3-light-grey' ; TeamA = 'w3-light-grey' , TeamB = 'w3-light-blue' )
        ;  Score = 'vs', TeamA = team, TeamB = team
      )
    },
    html(div([class("w3-light-grey w3-flex w3-padding w3-center"),style("gap:8px;flex-direction:column;margin: 8px 0")],
       [ span(class(TeamA), A)
       , span(b(Score))
       , span(class(TeamB), B)
       ])),
    lista_matches(T).




