# Entidades

Una entidad es un objeto del juego que tiene datos y comportamiento propio. Por ejemplo, `player.lua` representa al jugador y sabe actualizar su posición y dibujarse.

## Crear una entidad

```lua
local Objeto = {}
Objeto.__index = Objeto

function Objeto.new(x, y)
  return setmetatable({ x = x, y = y }, Objeto)
end

function Objeto:update(dt)
end

function Objeto:draw()
end

return Objeto
```

El estado que usa la entidad normalmente la crea en `enter` y la actualiza y dibuja desde sus propios métodos.
