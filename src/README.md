# Carpeta `src`

Aquí está el código propio del juego. La mayoría de los módulos siguen este patrón:

```lua
local modulo = {}

function modulo.hacer_algo()
end

return modulo
```

Usar `local` evita crear variables globales accidentalmente. Para utilizar el módulo desde otro archivo:

```lua
local Modulo = require("src/ruta/al/modulo")
Modulo.hacer_algo()
```

## `game.lua`

Es el punto central de coordinación. Aquí se crean los sistemas compartidos y se inicia la máquina de estados. No se debe poner aquí la lógica específica de una pantalla.

## `state_machine.lua`

Mantiene un único estado activo. Sus operaciones principales son:

```lua
StateMachine:switch("casa")
StateMachine:update(dt)
StateMachine:draw()
```

Los estados se registran dentro de `state_machine.lua`. Al añadir un estado nuevo, también hay que registrarlo allí.

## Cuidado con `:` y `.`

Los métodos que usan `self` se llaman con dos puntos:

```lua
player:update(dt)
```

Las funciones normales se llaman con un punto:

```lua
Game.update(dt)
```

Usar el operador incorrecto puede provocar errores difíciles de entender.
