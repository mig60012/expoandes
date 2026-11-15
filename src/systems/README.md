# Sistemas

Un sistema contiene una responsabilidad reutilizable. No representa una pantalla y normalmente no dibuja nada.

Ejemplos actuales:

- `economy.lua`: administra el dinero.
- `progress.lua`: conserva flags y valores de la partida.
- `decisions/conditions.lua`: consulta condiciones sin modificar el juego.
- `decisions/effects.lua`: aplica consecuencias al progreso o a la economía.
- `dialogue.lua`: carga y recorre líneas o nodos de diálogo.
- `dialogue_validator.lua`: comprueba referencias y estructura de los datos narrativos.
- `story_outcomes.lua`: convierte decisiones de una jornada en resultados como `N1` o `N2`.
- `day_flow.lua`: registra las decisiones temporales y finaliza jornadas.

## Crear un sistema

```lua
local Sistema = {}
Sistema.__index = Sistema

function Sistema.new()
  return setmetatable({}, Sistema)
end

function Sistema:hacer_algo()
end

return Sistema
```

El estado puede crear o recibir el sistema mediante el contexto:

```lua
local resultado = self.context.economy:spend_money(5)
```

Un sistema debe poder probarse o entenderse sin conocer qué estado lo está usando. Si empieza a contener mucho código de dibujo, probablemente parte de ese código pertenece a un estado o a una entidad.

## Decisiones

Las condiciones devuelven `resultado, error`. Un error siempre produce `false`; nunca se interpreta como una condición verdadera. Los efectos devuelven `true` si se aplicaron o `false, error` si no pudieron aplicarse.

Las condiciones de tipo `outcome` comparan resultados narrativos:

```lua
{
  type = "outcome",
  key = "N1",
  value = "A",
}
```

El efecto correspondiente es `set_outcome`:

```lua
{
  type = "set_outcome",
  key = "N1",
  value = "A",
}
```

El valor se valida contra las opciones declaradas al crear `Progress`.

## Resultados de una jornada

`story_outcomes.lua` contiene las reglas narrativas compartidas para los días
que utilizan la misma estructura:

```lua
local ok, outcome = StoryOutcomes.resolve_n1(context, {
  games = 3,
  spent_time_with_family = true,
})
```

El resultado será:

```text
3 partidas + familia → A
3 partidas + trabajo  → B
6 partidas            → C
```

`resolve_n2` utiliza exactamente la misma regla y escribe el resultado en
`N2`. La función no modifica el progreso si la combinación es inválida. Más
adelante el flujo de cada día deberá llamarla al terminar la jornada.

`resolve_n3` aplica las cuatro combinaciones específicas del Día 3:

```text
3 partidas + carro vendido + esposa informada     → N3 = A
3 partidas + carro conservado                     → N3 = B
6 partidas + carro vendido + esposa no informada  → N3 = C
6 partidas + carro conservado                    → N3 = D
```

Una combinación no descrita por el guion produce un error y no reemplaza el
resultado anterior.

`resolve_n5` registra la decisión económica del Día 5 utilizando nombres
descriptivos:

```lua
StoryOutcomes.resolve_n5(context, "mortgage")
StoryOutcomes.resolve_n5(context, "daughter_savings")
StoryOutcomes.resolve_n5(context, "none")
```

La traducción interna es:

```text
mortgage          → N5 = A
daughter_savings  → N5 = B
none              → N5 = C
```

## Flujo de jornadas

`DayFlow` coordina únicamente los datos de una jornada. No cambia estados ni
decide qué escena mostrar:

```lua
context.day_flow:start_day(1)
context.day_flow:record_games(3)
context.day_flow:finish_day() -- guarda N1 = A
```

Tres partidas registran inicialmente que todavía existe tiempo para la familia.
Si el jugador decide trabajar, se utiliza:

```lua
context.day_flow:record_work()
```

Esto cambia la actividad del día y produce `N1 = B` o `N2 = B`. Seis partidas
registran automáticamente que el protagonista pasó todo el día en el casino y
producen `N1 = C` o `N2 = C`.

Cuando un estado confirme que el protagonista volvió a casa sin haber elegido
trabajar, puede utilizar:

```lua
context.day_flow:record_return_home()
```

Esto registra el tiempo familiar y finaliza la jornada. La función no cambia
de estado; esa decisión sigue perteneciendo a la máquina de estados.

La transición de regreso utiliza esta regla al llegar a `casa`: tres partidas
llaman a `record_return_home()` y seis partidas llaman a `finish_day()` para
registrar `N1/N2 = C`. Si no se registraron tres o seis partidas, el regreso se
detiene y se muestra un error en lugar de guardar una jornada incompleta.

Después de terminar una jornada, el estado responsable puede llamar a:

```lua
context.day_flow:advance_after_finished_day()
```

Esto inicia el siguiente día, actualiza `current_day` y reinicia
`casino_games_today`. El método no cambia de pantalla.

Estos métodos son la interfaz recomendada para los estados. `record` se
mantiene disponible para decisiones futuras que no pertenezcan a esta regla.

Los estados de casa, trabajo y casino son responsables de registrar sus
decisiones. Al terminar una escena, el estado vuelve a entrar en `casa` o
cambia a `finales` según corresponda.

El estado `casino` puede registrar automáticamente tres o seis jugadas al
salir cuando existe una jornada activa. El estado `trabajo` registra la
actividad de trabajo al terminar. Si un estado se utiliza sin `context.day_flow`,
mantiene su comportamiento independiente para facilitar las pruebas.

Los efectos de dinero utilizan exclusivamente `context.economy`. El dinero no se duplica dentro de `Progress`.

## Rutas automáticas

Un nodo puede utilizar `routes` cuando el jugador no debe elegir y el juego
debe continuar según el progreso:

```lua
router = {
  routes = {
    {
      condition = {
        type = "value",
        key = "family_points",
        operator = ">=",
        value = 5,
      },
      next = "familia_unida",
    },
    { next = "familia_distante" }, -- ruta por defecto
  },
}
```

Las rutas se revisan en orden y se utiliza la primera que cumpla su condición.
Una ruta sin `condition` funciona como alternativa por defecto. No debe
colocarse `choices` y `routes` en el mismo nodo.

Al cargar un diálogo, `dialogue_validator.lua` comprueba que los destinos
referenciados existan. Esto permite detectar errores de escritura antes de
que el jugador llegue a esa parte de la historia.

`Progress:reset()` restaura los valores iniciales de la partida. Es útil para
reiniciar una partida y para preparar escenarios de prueba.

## Economía y finales

Los valores que el guion dejó abiertos están centralizados en
`context.rules` dentro de `src/game.lua`. `final_evaluation.lua` aplica los
límites narrativos:

```text
menos de 50 %       → final 1
50 % a menos de 100 % → final 2 o 3 según PF
100 %               → final 4
```

La pantalla `finales` presenta el resultado y permite reiniciar con `R`.

## Resultados narrativos

Los resultados categóricos de la historia se guardan en `outcomes`, separados
de los valores numéricos:

```lua
progress:set_outcome("N1", "A")
local resultado = progress:get_outcome("N1")
```

En `Game.context` se definen los valores válidos:

```text
N1: A, B, C
N2: A, B, C
N3: A, B, C, D
N5: A, B, C
```

`Progress` rechaza resultados desconocidos o valores que no pertenezcan a la
lista permitida. En esta fase los outcomes solo se almacenan; las condiciones
y efectos para utilizarlos desde diálogos se incorporarán posteriormente.
