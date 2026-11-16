# ExpoAndes Game

Videojuego desarrollado para ExpoAndes 2026, una feria universitaria de ingeniería sostenible.

El proyecto utiliza [LÖVE](https://love2d.org/) y Lua. La meta es crear una experiencia pequeña, clara y educativa sobre una problemática ambiental.

## Cómo ejecutar el juego

Desde la carpeta raíz del repositorio:

```bash
love .
```

También se puede arrastrar la carpeta del proyecto sobre el ejecutable de LÖVE. Se recomienda utilizar LÖVE 11.5 o una versión compatible.

Para probar rápidamente escenas y finales sin jugar toda la historia:

```bash
love . --story-test
```

El selector permite abrir el prólogo, las mañanas de los cinco días con sus
variantes y los cuatro finales. Usa `Arriba/Abajo` o `W/S`, `Enter` para abrir
una opción y `Esc` para volver al selector.

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

El juego comienza con el prólogo de `Historia.docx`: pantalla negra y fragmentos de hasta dos líneas. **Enter, Espacio o Z** avanzan el texto; **↑ / ↓** seleccionan las respuestas y el ratón también permite avanzar o elegir. Después comienza el día 1 en `casa`. Las conversaciones muestran al protagonista a la izquierda y a un solo interlocutor a la derecha, con modelos provisionales y el texto debajo, sin cubrirlos. Su puerta sale a `transicion`, donde puedes caminar con **A / D** y hacer clic en las puertas de la casa o del casino.

El carro se mueve al **doble** de la velocidad a pie; al venderlo desaparece y se aplica la velocidad de caminata. El celular ya no aparece en la casa. El maletín se conserva como parte del escenario y del código, pero no tiene hover ni interacción en esta iteración; trabajar sigue siendo una decisión del guion. Los cuadros de conversación ajustan su altura a una o dos líneas y a las opciones realmente visibles.

El casino usa el arte suministrado, recortado de la captura sin interfaz del teléfono ni borde ajedrezado. La textura se prolonga hasta los límites del mapa para que el encuadre no muestre zonas externas. Las tres mesas conservan su juego y tienen colisiones/capas de profundidad alineadas con el nuevo fondo. Detalles: [`docs/CASINO_ART.md`](docs/CASINO_ART.md).

La hora se conserva en `context.time_of_day`: `0` = mañana, `1` = tarde, `2` = noche. Al entrar a casa de noche se utiliza `assets/casa/fondo_noche.png`; de día se mantiene el fondo original. Al salir de casa o del casino, el personaje reaparece junto a la entrada correspondiente de la calle.

El guion recorre cinco días y conserva las decisiones de `DayFlow`, los resultados N1/N2/N3/N5 y la evaluación de los cuatro finales. El casino mantiene sus tandas obligatorias de **3 juegos** y la oferta de **3 más**. Volver temprano permite trabajar o estar en familia; volver tras seis juegos consume el día. El día 3 se decide la venta del carro, el día 4 ocurre la confrontación y el día 5 se elige entre trabajo/casino y después entre hipotecar, usar los ahorros o no hacerlo. Los finales usan pantalla negra y el mismo avance de dos líneas. El final 4 incluye una última apuesta guionizada de derrota garantizada; no modifica las probabilidades de las mesas normales. **R**, al terminar el epílogo, reinicia todos los datos y vuelve al prólogo.

La deuda es de **125 M**. El carro, la casa y los ahorros aportan respectivamente **10 M**, **15 M** y **10 M** al saldo real. El porcentaje final se calcula desde ese saldo, y los dos finales intermedios se separan en **5 puntos de familia**. En póker se elige la compra de fichas con un deslizador (100 fichas por 1 M); la compra sale de la cuenta y, al terminar la sesión, las fichas restantes vuelven proporcionalmente a ella.

La casa, calle, trabajo y casino muestran en la esquina superior izquierda los fondos actuales frente a la deuda total (`actual / 125 M`) y los puntos familiares frente al objetivo (`actual / 5`); ambos se ocultan durante el backstory y los finales. Los retratos suministrados de protagonista, esposa e hija reemplazan los modelos provisionales en las conversaciones de la casa. En la calle, el protagonista y el vagabundo usan sus retratos durante sus encuentros; los demás personajes conservan sus placeholders.

Las pruebas se ejecutan con `lua tests/run.lua`. `tests/test_transition_doors.lua` cubre las puertas, la cámara, los límites de movimiento y el fondo de la casa según la hora.

La adaptación completa está en `src/data/dialogues/historia.lua`; los textos abreviados anteriores siguen disponibles para compatibilidad y pruebas. `src/story.lua` conecta los encuentros con el flujo existente, y `src/ui/story_dialogue.lua` controla paginación, modelos provisionales y entradas. Consulta [`docs/STORY.md`](docs/STORY.md) para el mapa de escenas y los valores pendientes de balance.

Salir y volver al casino no reinicia el contador, el cansancio ni la decisión de jugar tres o seis juegos. Estos datos permanecen en el progreso de la partida; empezar una partida nueva los reinicia. Si ya completaste el límite elegido, las mesas siguen cerradas al volver. En póker debes terminar un juego completo de **3 manos** antes de salir, tanto con **Esc** como con **LEAVE**, para evitar cambiar las cartas abandonando y entrando de nuevo.
