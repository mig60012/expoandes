# ExpoAndes Game

Videojuego desarrollado para ExpoAndes 2026, una feria universitaria de ingeniería sostenible.

El proyecto utiliza [LÖVE](https://love2d.org/) y Lua. La meta es crear una experiencia pequeña, clara y educativa sobre una problemática ambiental.

## Cómo ejecutar el juego

Desde la carpeta raíz del repositorio:

```bash
love .
```

También se puede arrastrar la carpeta del proyecto sobre el ejecutable de LÖVE. Se recomienda utilizar LÖVE 11.5 o una versión compatible.

## Por dónde empezar

Si es tu primera vez en el proyecto, lee estos documentos en orden:

1. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): explicación general de la estructura.
2. [`src/README.md`](src/README.md): cómo se conectan los módulos.
3. [`src/states/README.md`](src/states/README.md): cómo crear una pantalla.
4. [`src/systems/README.md`](src/systems/README.md): cómo crear lógica reutilizable.

## Reglas importantes

- `main.lua` solo conecta LÖVE con `Game`; no se debe colocar allí la lógica del juego.
- Cada módulo debe ser local y terminar con `return nombre_del_modulo`.
- Los estados representan pantallas o etapas del juego.
- Los sistemas contienen lógica reutilizable y no deben dibujar directamente.
- Antes de crear una abstracción nueva, busca si ya existe un módulo que resuelva el problema.

## Estado actual

El juego comienza de día en `casa`. Su puerta sale a `transicion`, donde puedes caminar con **A / D** y hacer clic izquierdo en la puerta de la casa (extremo izquierdo) o del casino (extremo derecho). También puedes pulsar sus etiquetas visibles, «Entrar a casa» y «Entrar al casino». Las puertas se resaltan al pasar el cursor sobre ellas; no se pueden usar mientras hay un diálogo abierto.

La hora se conserva en `context.time_of_day`: `0` = mañana, `1` = tarde, `2` = noche. Al entrar a casa de noche se utiliza `assets/casa/fondo_noche.png`; de día se mantiene el fondo original. Al salir de casa o del casino, el personaje reaparece junto a la entrada correspondiente de la calle.

En el casino debes completar una primera tanda de **3 juegos** antes de salir. Se usa el contador existente: cada giro de ruleta y cada sesión completa de póker cuentan como una jugada. Al terminar el tercer juego, confirma el aviso para volver al salón; allí eliges si quieres jugar **3 más**. Usa **↑ / ↓** para elegir y **Z / Enter** para confirmar. Si rechazas, puedes salir de día. Si aceptas, se activa la noche y debes llegar a **6 juegos en total** antes de salir. Cambiar de mesa no reinicia el contador. Los avisos esperan a que termine el resultado del juego actual, sin interrumpir su pago. El blackjack sigue siendo un subestado provisional y todavía no registra juegos.

Las pruebas se ejecutan con `lua tests/run.lua`. `tests/test_transition_doors.lua` cubre las puertas, la cámara, los límites de movimiento y el fondo de la casa según la hora.

Salir y volver al casino no reinicia el contador, el cansancio ni la decisión de jugar tres o seis juegos. Estos datos permanecen en el progreso de la partida; empezar una partida nueva los reinicia. Si ya completaste el límite elegido, las mesas siguen cerradas al volver. En póker debes terminar un juego completo de **3 manos** antes de salir, tanto con **Esc** como con **LEAVE**, para evitar cambiar las cartas abandonando y entrando de nuevo.
