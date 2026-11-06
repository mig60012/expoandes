# Estados del juego

Un estado representa una pantalla o una etapa del juego: una casa, un menú, un minijuego o una animación.

## Estructura mínima

```lua
local mi_estado = {}

function mi_estado:enter(context)
  self.context = context
end

function mi_estado:update(dt)
end

function mi_estado:draw()
end

function mi_estado:keypressed(key, scancode, isrepeat)
end

function mi_estado:leave()
end

return mi_estado
```

Todos los métodos son opcionales. Solo crea los que el estado necesite.

## Ciclo de vida

- `enter`: se ejecuta al entrar al estado. Inicializa sus datos.
- `update(dt)`: se ejecuta cada cuadro. `dt` es el tiempo transcurrido en segundos desde el cuadro anterior.
- `draw`: dibuja el estado.
- `keypressed`: recibe una tecla cuando se pulsa.
- `leave`: limpia recursos temporales antes de salir.

## Crear un estado nuevo

1. Crea `src/states/mi_estado.lua`.
2. Implementa sus funciones.
3. Regístralo en `src/state_machine.lua`:

   ```lua
   mi_estado = require("src/states/mi_estado")
   ```

4. Cambia hacia él desde otro estado:

   ```lua
   self.context.state_machine:switch("mi_estado")
   ```

No importes directamente otro estado para cambiar de pantalla. Usa la máquina de estados.

## Buenas prácticas

- Inicializa los datos en `enter`, no al cargar el archivo.
- Mantén el estado responsable de su propia pantalla.
- Extrae a `entities/` los objetos grandes, como el jugador.
- Extrae a `systems/` las reglas que puedan reutilizarse en varias pantallas.
- No uses `love.graphics` dentro de sistemas que solo representan reglas.
