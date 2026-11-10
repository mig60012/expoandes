local Apuesta = {}
Apuesta.__index = Apuesta

function Apuesta.new(opciones)
  return setmetatable({
    minimo = opciones.minimo,
    maximo = opciones.dinero,
    monto = opciones.minimo,
  }, Apuesta)
end

return Apuesta
