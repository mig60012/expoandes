# Sistemas

Un sistema contiene una responsabilidad reutilizable. No representa una pantalla y normalmente no dibuja nada.

Ejemplos actuales:

- `economy.lua`: administra el dinero.
- `progress.lua`: conserva flags y valores de la partida.
- `decisions/conditions.lua`: consulta condiciones sin modificar el juego.
- `decisions/effects.lua`: aplica consecuencias al progreso o a la economía.
- `dialogue.lua`: carga y recorre líneas o nodos de diálogo.

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

Los efectos de dinero utilizan exclusivamente `context.economy`. El dinero no se duplica dentro de `Progress`.
