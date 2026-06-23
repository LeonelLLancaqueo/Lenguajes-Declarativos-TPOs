

* El juego llega hasta jugar la primer mano. luego se detiene el socket que debe jugar...


13/06
Ultimo log del juego -- SERVER

Iniciando juego con 2 jugadores
Jugadores y Cartas: [jugador(Daniel,[4-copa],[],[],<stream>(000001c13fd5ed70,000001c13fd5d3f0)),jugador(Leonel,[11-oro],[],[],<stream>(000001c13fd5cfb0,000001c13fd605e0))]
Jugadores y Cartas: [jugador(Daniel,[7-basto,4-copa],[],[],<stream>(000001c13fd5ed70,000001c13fd5d3f0)),jugador(Leonel,[6-copa,11-oro],[],[],<stream>(000001c13fd5cfb0,000001c13fd605e0))]
Jugadores y Cartas: [jugador(Daniel,[1-basto,7-basto,4-copa],[],[],<stream>(000001c13fd5ed70,000001c13fd5d3f0)),jugador(Leonel,[3-copa,6-copa,11-oro],[],[],<stream>(000001c13fd5cfb0,000001c13fd605e0))]
=== Ronda 1 ===
Turno de Daniel en ronda 1
Daniel jugÃ³: 1-basto
Turno de Leonel en ronda 1
Leonel jugÃ³: 6-copa
Todos los jugadores han jugado en ronda 1
Jugadores: [jugador(Daniel,[1-basto,7-basto,4-copa],[],[],<stream>(000001c13fd5ed70,000001c13fd5d3f0)),jugador(Leonel,[3-copa,6-copa,11-oro],[],[],<stream>(000001c13fd5cfb0,000001c13fd605e0))]
Cartas seleccionadas: [1-basto,6-copa]
Mejor carta: 1-basto
Jugadores Next: [jugador(Daniel,[7-basto,4-copa],[1-basto],[],<stream>(000001c13fd5ed70,000001c13fd5d3f0)),jugador(Leonel,[3-copa,11-oro],[6-copa],[],<stream>(000001c13fd5cfb0,000001c13fd605e0))]
Winner card is 1-basto from Daniel
=== Ronda 2 ===
Turno de Daniel en ronda 2
Daniel jugÃ³: 4-copa
Turno de Leonel en ronda 2
Leonel jugÃ³: 11-oro
Todos los jugadores han jugado en ronda 2
Jugadores: [jugador(Daniel,[7-basto,4-copa],[1-basto],[1-basto],<stream>(000001c13fd5ed70,000001c13fd5d3f0)),jugador(Leonel,[3-copa,11-oro],[6-copa],[],<stream>(000001c13fd5cfb0,000001c13fd605e0))]
Cartas seleccionadas: [4-copa,11-oro]
Mejor carta: 11-oro
Jugadores Next: [jugador(Daniel,[7-basto],[4-copa,1-basto],[1-basto],<stream>(000001c13fd5ed70,000001c13fd5d3f0)),jugador(Leonel,[3-copa],[11-oro,6-copa],[],<stream>(000001c13fd5cfb0,000001c13fd605e0))]
Winner card is 11-oro from Leonel
=== Ronda 3 ===
Turno de Leonel en ronda 3
Leonel jugÃ³: 3-copa
Turno de Daniel en ronda 3
Daniel jugÃ³: 7-basto
Todos los jugadores han jugado en ronda 3
Jugadores: [jugador(Leonel,[3-copa],[11-oro,6-copa],[11-oro],<stream>(000001c13fd5cfb0,000001c13fd605e0)),jugador(Daniel,[7-basto],[4-copa,1-basto],[1-basto],<stream>(000001c13fd5ed70,000001c13fd5d3f0))]
Cartas seleccionadas: [3-copa,7-basto]
Mejor carta: 3-copa
Jugadores Next: [jugador(Leonel,[],[3-copa,11-oro,6-copa],[11-oro],<stream>(000001c13fd5cfb0,000001c13fd605e0)),jugador(Daniel,[],[7-basto,4-copa,1-basto],[1-basto],<stream>(000001c13fd5ed70,000001c13fd5d3f0))]
Winner card is 3-copa from Leonel
Juego terminado
Hilo terminando para websocket
Servidor terminando...


log - JUGADOR

Mensaje: websocket{data:Esperando mÃ¡s jugadores...,format:string,opcode:text}
Esperando mensajes...
Mensaje: websocket{data:Â¡Juego iniciado!,format:string,opcode:text}
Esperando mensajes...
Mensaje: websocket{data:Ronda 1,format:string,opcode:text}
Esperando mensajes...
Mensaje: websocket{data:Turno de daniel,format:string,opcode:text}
Esperando mensajes...
Mensaje: websocket{data:daniel eligiÃ³ 10-oro,format:string,opcode:text}
Esperando mensajes...
Mensaje: websocket{data:Turno de leonel,format:string,opcode:text}
Esperando mensajes...
Â¡Es tu turno!
Mensaje: websocket{data:cartas([4-espada,4-basto,10-espada]),format:prolog,opcode:text}
Opciones disponibles: [4-espada,4-basto,10-espada]
|: 4-espada.
Jugada enviada: 4-espada
Esperando mensajes...
Mensaje: websocket{data:leonel eligiÃ³ 4-espada,format:string,opcode:text}
Esperando mensajes...
Mensaje: websocket{data:Ronda 2,format:string,opcode:text}
Esperando mensajes...
Mensaje: websocket{data:Turno de daniel,format:string,opcode:text}
Esperando mensajes...
Mensaje: websocket{data:daniel eligiÃ³ 11-basto,format:string,opcode:text}
Esperando mensajes...
Mensaje: websocket{data:Turno de leonel,format:string,opcode:text}
Esperando mensajes...
Â¡Es tu turno!
Mensaje: websocket{data:cartas([4-basto,10-espada]),format:prolog,opcode:text}
Opciones disponibles: [4-basto,10-espada]
Elige una opciÃ³n: |: 4-basto.
Jugada enviada: 4-basto
Esperando mensajes...
Mensaje: websocket{data:leonel eligiÃ³ 4-basto,format:string,opcode:text}
Esperando mensajes...
Â¡Juego terminado!
Desconectando...

FALTA 
    - definir ganador
    - llevar contador puntos
    - poder cantar truco
    - poder cantar envido
    - ganador de la mano empiece 
    - se termine a las 2 manos si es necesario.  


WEB 
    No permite --> 'Nombre' --> permite --> "nombre" 
    Reciben respuesta ok
    recibe y envia respuestas 
    hacer    
        --> input carta  