:- module(truco_web, [main/0]).

:- use_module(library(http/http_server)).
:- use_module(library(http/html_write)).
:- use_module(library(http/html_head)).
:- use_module(library(http/js_write)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/websocket)).
:- use_module(library(http/json)).
:- use_module(library(clpfd)).
:- use_module(library(http/http_files)).


:- initialization(main, main).

main :-
    http_server(http_dispatch, [port(8080)]),
    format('Cliente web Truco en http://localhost:8080~n', []).

:- http_handler(root(.), pagina_truco, []).

:- http_handler(root(static),
                http_reply_from_files('public', []),
                [prefix]).

pagina_truco(_Request) :-
    
    reply_html_page(
        [
            title('Truco Web'),
            link([
                rel(stylesheet),
                type('text/css'),
                href('/static/styles.css')
            ])
        ],
        [ 
            h1('Truco WebSocket'),
            img([class('img-truco'),src('/static/cartas_truco.png')]),
            
            p([class('anuncio'), id(log)],'Ingresa tu Nombre'),

            
            div([id(seccionJuego), class('contenedor-juego')],[
                input([class('input-name'),id(nombre)]),
                button([class('btn-jugar'),onclick('conectar()')], 'Jugar')
            ]),

            div([id(cartas),class('cartas')], []),

            div([id(apuesta), class('apuesta')],[]),


            \js_cliente
        ]
    ).

js_cliente -->
    html(script(type('text/javascript'), [
'
let ws = null;
let cartasActuales = [];

const regex = /-\\((\\d+),([a-z]+)\\)/g;
let nombre="";
apuestaHecha=false;

function log(txt) {
    document.getElementById("log").textContent = txt + "\\n";
}

function conectar() {
    nombre = document.getElementById("nombre").value;

    ws = new WebSocket("ws://localhost:8316/truco");

    ws.onopen = () => {
        log("Conectado al servidor");
        ws.send("join(" + nombre.toLowerCase() + ")");
        document.getElementById("seccionJuego").innerHTML="";
    };

    ws.onmessage = (event) => {
        procesarMensaje(event.data);
        console.log(event.data);
    };

    ws.onclose = () => {};
}

function procesarMensaje(msg) {

  
    if (msg.includes("responder") && !msg.includes(nombre)){
        log(msg);
        procesarApuesta();
        return;
    }    
    if (msg.startsWith("apuesta(") ) {
        apuestaHecha=true;
        const m = msg.match(/^apuesta\\(([^,]+),([^\\)]+)\\)$/);
        if (m) mostrarApuesta(m[1], m[2]);
        return;
    }

    if (msg == "jugar_carta"){
        document.getElementById("cartas").inert=false;
        document.getElementById("cartas").style.visibility = "visible";
        return;
    }

    if (msg.includes("Ganador")){
        const c= document.getElementById("cartas");
        c.innerHTML="";
        document.getElementById("apuesta").innerHTML="";   
        const logFinal= document.createElement("h2") ;
        logFinal.textContent= msg;
        c.appendChild(logFinal);
        return;
    }
    if (msg.includes("Puntos")){
        const c= document.getElementById("cartas");
        document.getElementById("apuesta").innerHTML="";   
        const logFinal= document.createElement("h2") ;
        logFinal.textContent= msg;
        c.appendChild(logFinal);
        return;
    }

    if(msg.startsWith("Juego iniciado")){
        log(msg);
        document.getElementById("seccionJuego").innerHTML="";
        const seccionJuego = document.getElementById("seccionJuego");
        const table= document.createElement("table");
        const tbody= document.createElement("tbody");

        const row1= document.createElement("tr");
        const row2= document.createElement("tr");
        row1.id="row1";
        row2.id="row2";
        table.appendChild(row1);
        table.appendChild(row2);

        seccionJuego.appendChild(table);
        return;
    }
    
    if (msg.startsWith("jugada") && !msg.includes(nombre)){    
        procesarJugadaRival(msg);
        return;
    }
    if (msg.startsWith("cartas(")) {
        const cartas = [];
        const regex = /([0-9]+)-(oro|copa|espada|basto)/g;
        let match;

        while ((match = regex.exec(msg)) !== null) {
            cartas.push(match[1] + "-" + match[2]);
        }

        mostrarCartas(cartas);
        mostrarOpApuesta();
        return;
    }
    if (!msg.startsWith("cartas(") && msg !=="Juego iniciado!") {
        log(msg);
        return;
    }
}

function procesarApuesta(){
    
    const cartasContainer = document.getElementById("cartas");
    cartasContainer.innerHTML = "";

    const btnQuiero = document.createElement("button");
    const btnNoQuiero = document.createElement("button");

    btnQuiero.classList.add("btn-carta");
    btnNoQuiero.classList.add("btn-carta");
    
    btnQuiero.textContent = "Quiero";
    btnNoQuiero.textContent = "No quiero";
    
    btnQuiero.onclick = () => responderApuesta("quiero");
    btnNoQuiero.onclick = () => responderApuesta("no_quiero");
    cartasContainer.appendChild(btnQuiero);   
    cartasContainer.appendChild(btnNoQuiero);
}

function responderApuesta(res){
    if (!ws) return;
    ws.send("respuesta_truco("+ res +")");
    document.getElementById("cartas").innerHTML = "";
}

function procesarJugadaRival(msg){

    const match = msg.match(/([0-9]+)-(oro|copa|espada|basto)/);

    if (!match) {
        console.log("No se encontró carta:", msg);
        return;
    }

    const carta = match[1] + "-" + match[2];

    console.log("Carta encontrada:", carta);

    const col = document.createElement("td");
    col.textContent = carta;

    document.getElementById("row1").appendChild(col);
}


    
function mostrarOpApuesta(){
    if (apuestaHecha !== true){
        const apuestaContainer = document.getElementById("apuesta");
        const btn = document.createElement("button");
        
        btn.classList.add("btn-carta");

        btn.textContent = "Truco";

        btn.onclick = () => cantar("truco");

        apuestaContainer.appendChild(btn);
    }
};

function mostrarCartas(cartas) {

    const cartasContainer = document.getElementById("cartas");

    cartasContainer.innerHTML = "";

    cartas.forEach(carta => {

        const btn = document.createElement("button");
        
        btn.classList.add("btn-carta");

        btn.textContent = carta;

        btn.onclick = () => jugarCarta(carta);

        cartasContainer.appendChild(btn);
    });
}
function jugarCarta(carta) {
    if (!ws) return;


    ws.send("carta(" + carta + ")");

    const col= document.createElement("td");
    col.textContent = carta;
    document.getElementById("row2").appendChild(col);

    document.getElementById("cartas").innerHTML = "";
    document.getElementById("apuesta").innerHTML = "";
}

function cantar(canto) {
    if (!ws) return;

    ws.send("truco(" + canto + ")");
    document.getElementById("cartas").inert=true;
    document.getElementById("cartas").style.visibility = "hidden";
    document.getElementById("apuesta").innerHTML = "";
    log("Cantaste: " + canto + "- esperando respuesta...");
}
function responderTruco(respuesta) {
    if (!ws) return;
    ws.send("respuesta_truco(" + respuesta + ")");
}
function mostrarApuesta(nombre, canto) {
    const logApuesta = document.getElementById("log");
    logApuesta.textContent += nombre + " canto " + canto + "\\n";
}

'
    ])).