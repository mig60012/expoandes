local Jornada = {}
Jornada.__index = Jornada

function Jornada.new()
  return setmetatable({ jugadas = 0 }, Jornada)
end

function Jornada:registrar_jugada()
  self.jugadas = self.jugadas + 1
end

return Jornada
