# Arquitectura del proyecto

Este documento explica cómo está organizado el juego y cómo se comunican sus partes. No es necesario conocer toda la arquitectura para empezar a trabajar: normalmente cada persona trabaja dentro de una carpeta concreta.

## Recorrido de una ejecución

1. LÖVE ejecuta `main.lua`.
2. `love.load()` llama a `Game.load()`.
3. `Game` crea el contexto compartido de la partida.
4. `StateMachine` carga los estados y entra en `transicion`.
5. En cada cuadro, LÖVE llama a `love.update` y `love.draw`.
6. `main.lua` reenvía esas llamadas a `Game` y `Game` las reenvía al estado actual.

La idea es que LÖVE solo conozca a `main.lua`, y que el resto del proyecto no dependa directamente de todos los callbacks de LÖVE.

## Carpetas

```text
main.lua              Punto de entrada de LÖVE
conf.lua              Configuración de la ventana y de LÖVE
src/
  game.lua            Coordinador general de la partida
  state_machine.lua   Cambia y ejecuta el estado actual
  states/             Pantallas o etapas del juego
    <state>/           Adaptadores visuales específicos del estado
  systems/            Lógica reutilizable
    decisions/        Condiciones y efectos reutilizables
  entities/           Objetos con datos y comportamiento propio
  data/               Diálogos y otros datos editables
lib/                  Librerías reutilizables de terceros
docs/                 Documentación del proyecto
```

## El contexto de la partida

`Game.context` contiene servicios que varios estados pueden necesitar. Por ejemplo:

```lua
self.context.economy:add_money(10)
self.context.progress:set_flag("car_sold", true)
self.context.state_machine:switch("casino")
```

Un estado recibe el contexto en su método `enter`. No se deben crear variables globales para compartir información.

## Progreso, condiciones y efectos

`context.progress` conserva las decisiones de la partida mediante `flags` booleanos y `values` numéricos. `conditions.lua` solo consulta el contexto y devuelve si una condición se cumple; `effects.lua` aplica cambios de manera explícita.

```lua
local condition = {
  type = "value",
  key = "family_points",
  operator = ">=",
  value = 5,
}

local allowed, err = Conditions.evaluate(condition, context)
```

Los datos narrativos pueden utilizar estos módulos, pero no contienen funciones ejecutables. Una opción puede tener `condition`, `effects` y `next`; primero se verifica que esté disponible, después se validan y aplican sus efectos y finalmente se avanza al nodo.

## Dependencias permitidas

- `main.lua` conoce a `Game`.
- `Game` conoce a la máquina de estados y crea el contexto.
- Los estados pueden usar sistemas y entidades.
- La interacción y presentación de un diálogo pertenece al estado que lo
  muestra; su recorrido narrativo pertenece a `systems/dialogue.lua`.
- Los sistemas no deben depender de un estado concreto.
- Las entidades no deben importar `main.lua`.
- Los datos no deben contener lógica del juego.

## Cómo decidir dónde poner código

- ¿Es una pantalla completa? → `src/states/`.
- ¿Es una regla reutilizable, como dinero o diálogos? → `src/systems/`.
- ¿Es un objeto que tiene posición, estado y comportamiento? → `src/entities/`.
- ¿Es texto o configuración que podría editar alguien no programador? → `src/data/`.

Si una función solo se usa en un estado, déjala en ese estado. No conviertas todo en un sistema desde el principio.
