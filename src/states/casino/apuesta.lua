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
    al_confirmar = opciones.al_confirmar,
    al_cancelar = opciones.al_cancelar,
  }, Apuesta)
end

function Apuesta:cambiar(cantidad)
  self.monto = math.max(self.minimo, math.min(self.maximo, self.monto + cantidad))
end

function Apuesta:confirmar()
  self.al_confirmar(self.monto)
end

function Apuesta:cancelar()
  self.al_cancelar()
end

return Apuesta
