# Sistemas

Un sistema contiene una responsabilidad reutilizable. No representa una pantalla y normalmente no dibuja nada.

Ejemplos actuales:

- `economy.lua`: administra el dinero.
- `dialogue.lua`: carga y recorre líneas de diálogo.

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
