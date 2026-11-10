local Apuesta = {}
Apuesta.__index = Apuesta

function Apuesta.new(opciones)
  if opciones.dinero < opciones.minimo then
    return nil
  end
  return setmetatable({
    minimo = opciones.minimo,
    maximo = opciones.dinero,
    monto = opciones.minimo,
  }, Apuesta)
end

return Apuesta
