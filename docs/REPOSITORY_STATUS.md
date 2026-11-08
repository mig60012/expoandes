# Arquitectura y estado actual del repositorio

> Documento de referencia para entender qué existe actualmente, qué hace cada parte y cuál debería ser su responsabilidad cuando el juego crezca.

## 1. Resumen

ExpoAndes es un videojuego pequeño desarrollado con **Lua** y **LÖVE 11.5**. El objetivo declarado es construir una experiencia clara y educativa relacionada con una problemática ambiental para ExpoAndes 2026.

El repositorio todavía está en una etapa inicial: existe un esqueleto ejecutable, una máquina de estados, una pantalla de transición en desarrollo, una pantalla de prueba con un jugador, algunos sistemas reutilizables y varias librerías auxiliares. No existe todavía un flujo de juego completo ni un diseño final implementado.

La arquitectura busca que:

- LÖVE se comunique únicamente con `main.lua`.
- `Game` coordine el contexto global de una partida.
- La máquina de estados controle qué pantalla está activa.
- Los estados representen pantallas o etapas completas.
- Los sistemas implementen reglas reutilizables, sin dibujar.
- Las entidades agrupen objetos con datos y comportamiento propio.
- Los datos editables estén separados del código.

## 2. Árbol actual

```text
.
├── main.lua                         # Entrada de LÖVE y puente de callbacks
├── conf.lua                         # Configuración principal de LÖVE
├── README.md                        # Introducción, ejecución y reglas generales
├── LICENSE                          # Mozilla Public License 2.0
├── assets/
│   ├── ugandan_knuckles.png         # Imagen usada por la transición actual
│   └── transicion/background.png    # Fondo de la transición actual
├── docs/
│   ├── ARCHITECTURE.md              # Arquitectura general existente
│   └── REPOSITORY_STATUS.md         # Este documento
├── lib/
│   ├── cards.lua                    # Cartas, mazos y manos
│   ├── camera.lua                   # Cámara 2D
│   ├── gamestate.lua                # Librería externa de estados
│   └── timer.lua                    # Librería externa de temporizadores
└── src/
    ├── game.lua                     # Coordinador de la partida
    ├── state_machine.lua            # Máquina de estados propia
    ├── entities/
    │   ├── player.lua               # Entidad de jugador de prueba
    │   └── README.md                # Documentación prevista de entidades
    ├── states/
    │   ├── casa.lua                 # Pantalla de prueba con jugador
    │   ├── casino.lua               # Esqueleto de posible minijuego
    │   ├── transicion.lua            # Pantalla de transición actualmente activa
    │   ├── animacion.lua             # Esqueleto de pantalla de animación
    │   ├── README.md                # Contrato y ciclo de vida de estados
    │   └── casino/pruebas/           # Ejecutor aislado de pruebas del casino
    ├── systems/
    │   ├── economy.lua               # Dinero de la partida
    │   ├── dialogue.lua              # Lectura y avance de diálogos
    │   └── README.md                # Convenciones para sistemas
    ├── data/
    │   ├── README.md                # Formato y uso de datos editables
    │   └── dialogues/dialogo.txt     # Diálogo de prueba
    └── README.md                    # Relación entre módulos principales
```

## 3. Flujo de ejecución real

Al ejecutar `love .` desde la raíz:

1. LÖVE carga `conf.lua` y configura la ventana.
2. LÖVE carga `main.lua`.
3. `main.lua` importa `src/game.lua`.
4. `love.load()` llama a `Game.load()`.
5. `Game.load()` crea `Game.context`, actualmente con:
   - una instancia de `Economy`;
   - la referencia a la máquina de estados.
6. `Game` inicializa `StateMachine`.
7. `StateMachine.load()` registra `casa`, `casino`, `transicion` y `animacion`.
8. El código actual cambia inmediatamente a **`transicion`**.
9. En cada cuadro, `main.lua` reenvía `update`, `draw` y eventos de teclado a `Game`; `Game` los reenvía al estado activo.

### Diferencia documental importante

El `README.md` raíz indica que `casa` es el estado inicial, pero `src/state_machine.lua` ejecuta `switch("transicion")`. Por tanto, **el comportamiento actual es `transicion`**, no `casa`. Esta diferencia debe resolverse cuando se defina el flujo inicial definitivo; mientras tanto, este documento describe el código real.

## 4. Responsabilidad de cada nivel

### Raíz

#### `main.lua`

Es el adaptador entre LÖVE y el juego. Registra los callbacks principales (`load`, `update`, `draw`, `keypressed` y `keyreleased`) y los delega a `Game`.

**Debe hacer:** conectar callbacks y pasar argumentos.

**No debe hacer:** contener reglas, crear pantallas, administrar dinero o dibujar directamente.

#### `conf.lua`

Define la configuración de LÖVE: versión 11.5, título, resolución base de 800×600 y pantalla completa de tipo `desktop`. También activa o desactiva módulos de LÖVE.

**Debe hacer:** contener únicamente configuración global de ejecución.

### `src/game.lua`

Es el coordinador de la partida. Construye el contexto compartido y delega el ciclo de vida y los eventos a `StateMachine`.

Actualmente crea `context.economy` y `context.state_machine`. En el futuro puede agregar servicios compartidos como progreso, inventario, audio o configuración, pero no debería convertirse en una pantalla ni almacenar lógica específica de una escena.

### `src/state_machine.lua`

Mantiene un único estado activo y expone:

- `load(context)`: registra estados y selecciona el inicial.
- `switch(name, ...)`: abandona el estado anterior y entra en otro.
- `update(dt)`, `draw()`: delegan al estado activo.
- `keypressed(...)`, `keyreleased(...)`: delegan entrada.

El cambio de pantalla debe hacerse con `self.context.state_machine:switch("nombre")`, no importando y llamando otro estado directamente.

Los métodos de estado son opcionales. El ciclo esperado es `enter`, `update`, `draw`, eventos de entrada y `leave`.

### `src/states/`

Cada archivo representa una pantalla o etapa completa. Un estado recibe el contexto en `enter`, mantiene sus datos temporales y decide qué dibujar.

#### `casa.lua`

Es la implementación más simple de una pantalla jugable: crea un `Player` en `(500, 500)`, muestra el texto `Casa - estado de prueba` y actualiza/dibuja al jugador.

**Estado:** demostración funcional, no una casa o nivel terminado.

#### `transicion.lua`

Es el estado que se ejecuta actualmente. Dibuja un fondo, una imagen de jugador y un cuadro de diálogo. Permite desplazar la imagen con `A` y `D`, y activar/avanzar el diálogo con `Espacio`.

**Estado:** prototipo en desarrollo. Tiene datos y objetos en variables locales del archivo, posiciones fijas y texto de diagnóstico del mouse; todavía no es una transición integrada con el resto del flujo.

#### `casino.lua`

Es un esqueleto visual de un posible casino o minijuego. Mueve un círculo mediante seno y coseno y muestra un texto de estado pendiente.

**Estado:** placeholder. No usa todavía `Economy`, `cards.lua` ni las pruebas del directorio vecino.

#### `animacion.lua`

Solo conserva el contexto y muestra `Animación - estado pendiente`.

**Estado:** placeholder preparado para una futura secuencia animada.

### `src/entities/`

#### `player.lua`

Define una entidad `Player` con posición, velocidad y tamaño. La instancia responde a `WASD` y a las flechas, y se dibuja como un rectángulo sin relleno.

**Debe hacer:** encapsular el estado y comportamiento del jugador.

**Estado:** entidad mínima de prueba. Aún no tiene límites, colisiones, animaciones, interacción ni conexión con una cámara.

### `src/systems/`

Los sistemas representan reglas que pueden ser usadas por varios estados y, por diseño, no deben dibujar.

#### `economy.lua`

Gestiona el dinero mediante `get_money`, `add_money` y `spend_money`. Rechaza cantidades negativas y devuelve `false` si no hay saldo suficiente para gastar.

**Estado:** funcional como servicio aislado, pero todavía no está conectado a una pantalla jugable.

#### `dialogue.lua`

Carga un archivo de texto desde `src/data/dialogues/`, interpreta cada línea como una entrada y permite consultar la línea actual o avanzar.

**Estado:** funcional para diálogos lineales simples. No conoce personajes, decisiones, efectos ni formato estructurado. El estado de transición es quien decide cómo mostrarlo.

### `src/data/`

Contiene información editable sin modificar la lógica. Actualmente solo hay un diálogo de texto.

Cada línea de un `.txt` se interpreta como una línea independiente. Si se añaden personajes, decisiones o efectos, primero debe definirse y documentarse un formato estable.

### `assets/`

Contiene recursos gráficos usados por el prototipo. La carga actual se hace desde `transicion.lua` con rutas relativas a la raíz del proyecto.

En el futuro conviene organizar los recursos por tipo o pantalla y centralizar, si aumenta el número de archivos, la carga de imágenes y sonidos.

### `lib/`

Son librerías reutilizables, separadas del código propio del juego.

- **`cards.lua`**: fábrica y clases para cartas, mazos y manos; incluye baraja estándar, mezcla, robo, devolución y animación de giro. Es la pieza más relacionada con el posible casino, pero todavía no está conectada a `casino.lua`.
- **`camera.lua`**: cámara 2D con posición, zoom, rotación, transformaciones y seguimiento. No está usada por el flujo actual.
- **`gamestate.lua`**: librería externa de máquina de estados basada en pila y callbacks de LÖVE. El proyecto utiliza `src/state_machine.lua` en su lugar; no deben mezclarse ambas soluciones sin una decisión explícita.
- **`timer.lua`**: librería externa para acciones diferidas, repetitivas y secuencias con coroutines. No está integrada todavía.

Las librerías conservan avisos de licencia propios; cualquier modificación o redistribución debe respetar esos avisos además de la licencia del repositorio.

## 5. Pruebas del casino

`src/states/casino/pruebas/` es un ejecutable LÖVE independiente del flujo principal. Incluye:

- `probador.lua`: pequeño framework de aserciones y agrupación de pruebas.
- `prueba_probador.lua`: pruebas del propio framework.
- `main.lua`: carga las pruebas, muestra un informe y permite repetirlas con `R`.
- `conf.lua`: configuración aislada para pruebas.

El modo `--auto` escribe `resultado.txt` en el directorio de guardado de LÖVE y termina con código 0 si no hay fallos o 1 si los hay. Este directorio no es una suite del juego completo: actualmente prueba principalmente el probador.

## 6. Contratos de dependencia

La dirección recomendada de dependencias es:

```text
LÖVE → main.lua → Game → StateMachine → Estado
                                      ├── Entidades
                                      ├── Sistemas
                                      └── Datos
```

Reglas que deberían mantenerse:

1. `main.lua` conoce a `Game`, no a cada estado.
2. `Game` crea el contexto y arranca la máquina de estados.
3. Los estados pueden usar sistemas, entidades, datos y librerías.
4. Los sistemas no deben depender de un estado concreto ni dibujar.
5. Las entidades no deben importar `main.lua`.
6. Los datos no deben contener lógica.
7. Un estado no debe cambiar a otro llamándolo directamente; debe usar la máquina.
8. Los módulos deben ser locales y devolver su módulo con `return`.
9. Las funciones con `self` usan `:`, y las funciones normales usan `.`.
10. La información compartida debe viajar por `Game.context`, no mediante variables globales.

## 7. Estado funcional resumido

| Área | Estado actual | Comportamiento esperado |
|---|---|---|
| Arranque | Funcional con LÖVE 11.5 | Mantener `main.lua` como adaptador mínimo |
| Coordinación | `Game` y máquina propias funcionando | Centralizar aquí solo el ciclo y contexto |
| Estado inicial | Entra en `transicion`; README dice `casa` | Elegir y documentar un único flujo inicial |
| Casa | Jugador rectangular controlable | Convertirse en nivel o pantalla real |
| Transición | Fondo, imagen y diálogo de prueba | Controlar una transición y avanzar al siguiente estado |
| Casino | Círculo animado | Integrar reglas, cartas y economía cuando exista diseño |
| Animación | Texto placeholder | Implementar una secuencia real o eliminar el estado |
| Economía | Servicio aislado funcional | Ser consumida por actividades del juego |
| Diálogos | Texto lineal funcional | Definir formato si necesita decisiones o personajes |
| Datos | Un archivo de texto de prueba | Separar contenido definitivo de prototipos |
| Pruebas | Framework y pruebas propias | Añadir pruebas de sistemas y reglas del juego |
| Librerías | Varias, algunas sin uso | Integrar solo las necesarias y documentar su origen |

## 8. Aspectos pendientes y riesgos actuales

- **Flujo inicial inconsistente:** `casa` y `transicion` compiten como punto de entrada documental y real.
- **Estado global de la máquina:** `state_machine.lua` es una tabla singleton. Funciona para una partida, pero dificulta ejecutar varias instancias o aislar pruebas.
- **Código de transición con estado a nivel de módulo:** posición del jugador y diálogo sobreviven entre entradas al estado. Si se entra varias veces, los datos no se reinician completamente en `enter`.
- **Diálogo al final:** `current_line()` puede devolver `nil` después de avanzar más allá de la última línea; la transición debería manejar explícitamente el final.
- **Recursos cargados al importar:** `transicion.lua` crea imágenes y el diálogo al hacer `require`, en lugar de hacerlo al entrar o cargar recursos de forma controlada.
- **Pruebas limitadas:** no hay pruebas automatizadas para economía, diálogo, estados, jugador o flujo de transición.
- **Librerías no integradas:** `cards`, `camera`, `gamestate` y `timer` parecen preparadas para futuras funcionalidades, pero no forman parte del flujo actual.
- **Prototipos visibles:** texto de diagnóstico, coordenadas del mouse y nombres de prueba aún aparecen en pantalla o en los datos.

## 9. Orden recomendado para continuar

1. Definir el flujo de pantallas y decidir si el arranque es `transicion` o `casa`.
2. Eliminar o marcar claramente los datos y recursos de prueba.
3. Hacer que cada estado inicialice su propio estado temporal en `enter`.
4. Definir el diseño del juego y qué papel cumplen el casino, la economía y los diálogos.
5. Integrar solo las librerías necesarias; evitar mantener dos máquinas de estados.
6. Añadir pruebas para `economy`, `dialogue` y las reglas de los minijuegos antes de ampliar la interfaz.
7. Completar el flujo de transición entre estados y documentar cada cambio.
8. Mantener actualizados `README.md`, `docs/ARCHITECTURE.md` y este documento cuando cambie la estructura.

## 10. Ejecución

Desde la raíz:

```bash
love .
```

Se recomienda LÖVE 11.5 o una versión compatible. El ejecutable de pruebas del casino se debe lanzar desde su propia carpeta si se desea comprobar el probador de forma aislada.
