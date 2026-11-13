local Jornada = {}
Jornada.__index = Jornada

function Jornada.new(opciones)
  return setmetatable({ jugadas = 0, maximo = opciones.maximo, cansancio = opciones.cansancio }, Jornada)
end

function Jornada:registrar_jugada()
  self.jugadas = self.jugadas + 1
end

function Jornada:completa()
  return self.jugadas >= self.maximo
end

function Jornada:factor_velocidad()
  return 1 - self.cansancio * self.jugadas
end

return Jornada
